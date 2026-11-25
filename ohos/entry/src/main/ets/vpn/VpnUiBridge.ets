import { rpc } from '@kit.IPCKit';
import { vpnExtension } from '@kit.NetworkKit';
import { bundleManager, common } from '@kit.AbilityKit';
import type Want from '@ohos.app.ability.Want';
import { VpnLog } from './VpnLog';
import { VpnRpc } from './VpnRpc';
import { VpnTunStore } from './VpnTunStore';

/** Outcome of a single attempt to pull the TUN descriptor over RPC. */
interface TunFdResult {
  fd: number;
  reason: string;
}

/**
 * UI-process side of the HarmonyOS VPN bridge.
 *
 * Responsibilities:
 *  1. expose a method channel the Dart side can call;
 *  2. start the VPN Extension, which creates the TUN device;
 *  3. pull the TUN descriptor out of the extension process over RPC;
 *  4. hand the descriptor to Dart.
 *
 * The descriptor has to be duplicated into this process: the VPN service only
 * hands it to the process that asked for the tunnel, and that is the VPN
 * extension process, not the one hosting the Go core.
 */
export class VpnUiBridge {
  private static instance: VpnUiBridge | undefined = undefined;

  private bundleName: string = '';
  private context: common.UIAbilityContext | undefined = undefined;
  private remote: rpc.IRemoteObject | undefined = undefined;
  private connectionId: number = -1;

  static getInstance(): VpnUiBridge {
    if (!VpnUiBridge.instance) {
      VpnUiBridge.instance = new VpnUiBridge();
    }
    return VpnUiBridge.instance;
  }

  setBundleName(bundleName: string): void {
    this.bundleName = bundleName;
  }

  /**
   * The UI ability context is needed to reach the VPN extension process,
   * because `connectServiceExtensionAbility` is only available on a UI
   * ability.
   */
  setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
   * Starts the VPN Extension and resolves with its TUN file descriptor.
   */
  async prepare(timeoutMs: number = 20000): Promise<number> {
    await this.stop();

    // The system tears the previous VPN session down asynchronously: the
    // extension process is still running its onDestroy() (destroyTunDevice)
    // after stopVpnExtensionAbility() has returned. Starting a new session
    // immediately makes the fresh extension race with that teardown, which
    // shows up as a connect attempt that never resolves. Let it settle.
    await this.delay(300);

    // 1. Start the VPN extension. The system creates the VPN session and the
    //    extension process, where the TUN device is created.
    await this.startExtensionWithRetry();

    // 2. Pull the descriptor out of the extension process.
    //
    // There is no in-process fallback worth waiting for: the extension always
    // runs in its own process, so the descriptor can only arrive over RPC.
    // Failing fast surfaces the real error instead of stalling the connect
    // button for a minute.
    let fd = -1;
    try {
      fd = await this.withTimeout(this.pullTunFd(), timeoutMs);
    } catch (error) {
      // Never leave a half-started session behind, a leaked extension would
      // break the next attempt as well.
      VpnLog.warn('failed to obtain the tun descriptor: ' + JSON.stringify(error));
      await this.stop();
      throw error as Error;
    }
    if (fd <= 0) {
      await this.stop();
      throw new Error('the vpn extension did not return a tun descriptor');
    }
    VpnLog.info('the tun descriptor has been received: ' + fd);
    return fd;
  }

  /**
   * startVpnExtensionAbility() is rejected while the system is still winding
   * down the previous session, so a couple of attempts are required for a
   * stop/start cycle (reconnect, network switch) to be reliable.
   */
  private async startExtensionWithRetry(attempts: number = 3): Promise<void> {
    const want: Want = {
      bundleName: this.bundleName,
      abilityName: VpnRpc.VPN_ABILITY_NAME,
    };
    let lastError = '';
    for (let attempt = 0; attempt < attempts; attempt++) {
      try {
        await vpnExtension.startVpnExtensionAbility(want);
        VpnLog.info('the vpn extension has been started');
        return;
      } catch (error) {
        lastError = JSON.stringify(error);
        VpnLog.warn(
          'starting the vpn extension failed (attempt ' + (attempt + 1) + '): ' + lastError,
        );
        await this.delay(400 * (attempt + 1));
      }
    }
    throw new Error('unable to start the vpn extension: ' + lastError);
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => resolve(), ms);
    });
  }

  /**
   * Tears the VPN Extension down.
   */
  async stop(): Promise<void> {
    this.remote = undefined;

    const context = this.context;
    if (context && this.connectionId !== -1) {
      try {
        await context.disconnectServiceExtensionAbility(this.connectionId);
      } catch (error) {
        VpnLog.warn('failed to disconnect the vpn extension: ' + JSON.stringify(error));
      }
      this.connectionId = -1;
    }

    VpnTunStore.clear();

    if (!this.bundleName) {
      return;
    }
    const want: Want = {
      bundleName: this.bundleName,
      abilityName: VpnRpc.VPN_ABILITY_NAME,
    };
    try {
      await vpnExtension.stopVpnExtensionAbility(want);
    } catch (error) {
      // 16000001 means the extension was not running, which is fine.
      VpnLog.info('stop vpn extension: ' + JSON.stringify(error));
    }
  }

  /**
   * Connects to the VPN extension process and asks it for the descriptor.
   */
  private async pullTunFd(): Promise<number> {
    const remote = await this.connectToExtension();
    this.remote = remote;
    return await this.requestTunFd(remote);
  }

  /**
   * Opens the RPC channel to the VPN extension process.
   */
  private async connectToExtension(): Promise<rpc.IRemoteObject> {
    const context = this.context;
    if (!context) {
      throw new Error('the ui ability context is not available');
    }

    const want: Want = {
      bundleName: this.bundleName,
      abilityName: VpnRpc.VPN_ABILITY_NAME,
    };

    return await new Promise<rpc.IRemoteObject>((resolve, reject) => {
      const options: common.ConnectOptions = {
        onConnect: (elementName: bundleManager.ElementName, remote: rpc.IRemoteObject): void => {
          VpnLog.info('connected to the vpn extension process');
          resolve(remote);
        },
        onDisconnect: (elementName: bundleManager.ElementName): void => {
          VpnLog.warn('the vpn extension disconnected');
        },
        onFailed: (code: number): void => {
          reject(new Error('failed to connect to the vpn extension, code ' + code));
        },
      };
      this.connectionId = context.connectServiceExtensionAbility(want, options);
    });
  }

  /**
   * Asks the extension process for the TUN descriptor.
   *
   * The system finishes creating the tunnel a little after the extension is
   * started, so the first few requests legitimately answer `not-ready`. Keep
   * polling until the descriptor shows up, then stop.
   */
  private async requestTunFd(remote: rpc.IRemoteObject): Promise<number> {
    const deadline = Date.now() + 30000;
    let attempt = 0;
    let lastReason = '';
    while (Date.now() < deadline) {
      attempt++;
      const result = await this.tryReadTunFd(remote);
      if (result.fd > 0) {
        VpnLog.info('the reply parcel carries fd ' + result.fd + ' (attempt ' + attempt + ')');
        return result.fd;
      }
      lastReason = result.reason;
      if (attempt === 1 || attempt % 25 === 0) {
        VpnLog.warn('tun fd attempt ' + attempt + ': ' + result.reason);
      }
      await this.sleep(200);
    }
    throw new Error('timed out waiting for the tun descriptor, last reason: ' + lastReason);
  }

  /**
   * Performs a single request/reply round trip.
   *
   * Both parcels are recreated per attempt: `MessageSequence` is single-use
   * and a replayed parcel would carry the previous payload.
   */
  private async tryReadTunFd(remote: rpc.IRemoteObject): Promise<TunFdResult> {
    const data = rpc.MessageSequence.create();
    const reply = rpc.MessageSequence.create();

    // The reply parcel has to accept file descriptors, otherwise the
    // descriptor the extension writes into it is dropped. `setFlags` is used
    // instead of the constructor because the constructor documents only 0/1
    // as syncFlags and may normalise a raw bitmask away.
    const options = new rpc.MessageOption(rpc.MessageOption.TF_SYNC);
    options.setFlags(rpc.MessageOption.TF_ACCEPT_FDS);

    try {
      await remote.sendMessageRequest(VpnRpc.CODE_GET_TUN_FD, data, reply, options);
    } catch (error) {
      return { fd: -1, reason: 'request failed: ' + JSON.stringify(error) };
    }

    let fd = -1;
    let parcelInfo = '';
    try {
      parcelInfo = 'size=' + reply.getSize() + ' hasFd=' + reply.containFileDescriptors();
      fd = reply.readFileDescriptor();
    } catch (error) {
      // 1900010 means the parcel holds a plain string instead of a descriptor,
      // i.e. the extension is not ready yet.
      fd = -1;
    }
    if (fd > 0) {
      return { fd: fd, reason: '' };
    }

    let reason = '';
    try {
      reason = reply.readString();
    } catch (error) {
      reason = 'unknown';
    }
    return { fd: -1, reason: reason + ' [' + parcelInfo + ']' };
  }

  private sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => resolve(), ms);
    });
  }

  private async withTimeout(promise: Promise<number>, timeoutMs: number): Promise<number> {
    let timer: number = -1;
    const timeout = new Promise<number>((_resolve, reject) => {
      timer = setTimeout(() => {
        reject(new Error('timed out while waiting for the tun file descriptor'));
      }, timeoutMs);
    });
    try {
      return await Promise.race([promise, timeout]);
    } finally {
      if (timer !== -1) {
        clearTimeout(timer);
      }
    }
  }
}
