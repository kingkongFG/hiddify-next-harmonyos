
import {
  FlutterAbility,
  FlutterEngine,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { AbilityConstant, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { connection } from '@kit.NetworkKit';
import type Want from '@ohos.app.ability.Want';
import process from '@ohos.process';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { OhosPlatformRpc, OhosPlatformService } from '../platform/OhosPlatformService';
import { VpnLog } from '../vpn/VpnLog';
import { VpnRpc } from '../vpn/VpnRpc';
import { VpnUiBridge } from '../vpn/VpnUiBridge';

/**
 * Adapts the `MethodCallHandler` interface (a single `onMethodCall` method) to
 * a plain callback. ArkTS does not allow a bare arrow function to be assigned
 * to an interface-typed parameter, so the handler is wrapped in a class.
 */
class VpnMethodCallHandler implements MethodCallHandler {
  private callback: (call: MethodCall, result: MethodResult) => void;

  constructor(callback: (call: MethodCall, result: MethodResult) => void) {
    this.callback = callback;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.callback(call, result);
  }
}

export default class EntryAbility extends FlutterAbility {
  /**
   * The Go core runs inside this UI process. HarmonyOS freezes a background
   * application after a short while, which suspends every goroutine of the
   * core: the TUN descriptor stays open, the system keeps routing traffic
   * into it, but nobody reads it any more. Every application then loses
   * connectivity even though the tunnel is still reported as up.
   *
   * A continuous task keeps the process out of the freezer while the VPN is
   * connected.
   */
  private continuousTaskRunning: boolean = false;

  /** Channel used for Dart -> native calls and native -> Dart events. */
  private vpnChannel: MethodChannel | undefined = undefined;

  /** True while the tunnel is up; network events are ignored otherwise. */
  private vpnActive: boolean = false;

  /** netId of the physical network the current tunnel was built on. */
  private lastNetId: number = -1;

  private netConnection: connection.NetConnection | undefined = undefined;
  private networkChangeTimer: number = -1;

  private async startContinuousTask(): Promise<void> {
    if (this.continuousTaskRunning) {
      return;
    }
    try {
      const info: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: this.context.abilityInfo.bundleName,
            abilityName: 'EntryAbility',
          },
        ],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      };
      const agent = await wantAgent.getWantAgent(info);
      await backgroundTaskManager.startBackgroundRunning(
        this.context,
        backgroundTaskManager.BackgroundMode.DATA_TRANSFER,
        agent,
      );
      this.continuousTaskRunning = true;
      VpnLog.info('continuous task started, the core stays alive in background');
    } catch (error) {
      // Without the continuous task the tunnel still works while the app is
      // in the foreground, so report it without failing the connect flow.
      VpnLog.warn('failed to start the continuous task: ' + JSON.stringify(error));
    }
  }

  private async stopContinuousTask(): Promise<void> {
    if (!this.continuousTaskRunning) {
      return;
    }
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context);
      VpnLog.info('continuous task stopped');
    } catch (error) {
      VpnLog.warn('failed to stop the continuous task: ' + JSON.stringify(error));
    }
    this.continuousTaskRunning = false;
  }

  /**
   * Watches the default physical network.
   *
   * The Go core opens outbound sockets without binding an interface and
   * `protectProcessNet()` is applied exactly once, when the TUN is created.
   * When Wi-Fi gives way to cellular the kernel tears down every socket on
   * the old netId; sockets opened on the new netId are not covered by that
   * protection and are aborted with ECONNABORTED. sing-box's own netlink
   * based network monitor cannot start in an app process (EPERM), so it
   * never resets conntrack/DNS either. The tunnel stays up and swallows all
   * traffic until the app is restarted.
   *
   * Rebuilding the tunnel on the new network re-applies the protection and
   * gives lwip, DNS and conntrack a clean slate. A 2.5s debounce collapses
   * the burst of netLost/netAvailable events, and comparing the physical
   * netId prevents our own VPN interface from re-triggering a rebuild.
   */
  private startNetworkWatch(): void {
    try {
      const netConn = connection.createNetConnection();
      const schedule = (reason: string): void => {
        if (!this.vpnActive) {
          return;
        }
        if (this.networkChangeTimer !== -1) {
          clearTimeout(this.networkChangeTimer);
        }
        this.networkChangeTimer = setTimeout(() => {
          this.networkChangeTimer = -1;
          this.onNetworkSettled(reason);
        }, 2500);
      };
      netConn.on('netLost', (_: connection.NetHandle): void => schedule('netLost'));
      netConn.on('netAvailable', (_: connection.NetHandle): void => schedule('netAvailable'));
      netConn.register((error): void => {
        if (error) {
          VpnLog.warn('failed to register the network watcher: ' + JSON.stringify(error));
        } else {
          VpnLog.info('the network watcher has been registered');
        }
      });
      this.netConnection = netConn;
    } catch (error) {
      VpnLog.warn('failed to start the network watcher: ' + JSON.stringify(error));
    }
  }

  /** Reads the netId of the current default physical (non-VPN) network. */
  private currentNetId(): number {
    try {
      return connection.getDefaultNetSync().netId;
    } catch (error) {
      return -1;
    }
  }

  private onNetworkSettled(reason: string): void {
    if (!this.vpnActive) {
      return;
    }
    const netId = this.currentNetId();
    if (netId <= 0) {
      // The new physical network is not up yet. Its netAvailable event will
      // schedule another check once it is, so there is nothing to do here.
      VpnLog.warn('default network is not ready yet (' + reason + ')');
      return;
    }
    if (netId === this.lastNetId) {
      return;
    }
    VpnLog.info('default network changed (' + reason + '): ' + this.lastNetId + ' -> ' + netId);
    this.lastNetId = netId;
    const channel = this.vpnChannel;
    if (channel) {
      channel.invokeMethod(VpnRpc.METHOD_NETWORK_CHANGED, {});
    }
  }

  private rememberCurrentNetwork(): void {
    this.lastNetId = this.currentNetId();
    VpnLog.info('the tunnel is bound to netId ' + this.lastNetId);
  }

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)

    VpnLog.info('the ui ability runs in pid ' + process.pid);

    // HarmonyOS VPN bridge: the Dart side drives the system VPN Extension
    // through this channel and receives the TUN file descriptor back.
    const bridge = VpnUiBridge.getInstance();
    bridge.setBundleName(this.context.abilityInfo.bundleName);
    // The VPN extension process is reached through the UI ability context,
    // so the bridge needs a reference to it.
    bridge.setContext(this.context);

    const channel = new MethodChannel(
      flutterEngine.dartExecutor.getBinaryMessenger(),
      VpnRpc.CHANNEL,
    );
    const handler = new VpnMethodCallHandler((call: MethodCall, result: MethodResult): void => {
      this.handleVpnMethodCall(call, result);
    });
    channel.setMethodCallHandler(handler);
    this.vpnChannel = channel;

    // Clipboard / system-share bridge. Kept on its own channel so VPN calls
    // and platform services cannot block each other.
    const platformService = OhosPlatformService.getInstance();
    platformService.setContext(this.context);
    const platformChannel = new MethodChannel(
      flutterEngine.dartExecutor.getBinaryMessenger(),
      OhosPlatformRpc.CHANNEL,
    );
    platformChannel.setMethodCallHandler(
      new VpnMethodCallHandler((call: MethodCall, result: MethodResult): void => {
        this.handlePlatformMethodCall(call, result);
      }),
    );

    this.startNetworkWatch();
  }

  private async handlePlatformMethodCall(
    call: MethodCall,
    result: MethodResult,
  ): Promise<void> {
    const service = OhosPlatformService.getInstance();
    switch (call.method) {
      case OhosPlatformRpc.METHOD_READ_CLIPBOARD:
        result.success(await service.readClipboardText());
        break;
      case OhosPlatformRpc.METHOD_WRITE_CLIPBOARD: {
        const text = call.argument(OhosPlatformRpc.ARG_TEXT) as string;
        result.success(await service.writeClipboardText(text ?? ''));
        break;
      }
      case OhosPlatformRpc.METHOD_SHARE_TEXT: {
        const text = call.argument(OhosPlatformRpc.ARG_TEXT) as string;
        const title = call.argument(OhosPlatformRpc.ARG_TITLE) as string;
        result.success(await service.shareText(text ?? '', title ?? ''));
        break;
      }
      default:
        result.notImplemented();
        break;
    }
  }

  /**
   * The VPN extension hands the TUN descriptor over through the want of this
   * ability. Harmless when the extension is reachable over RPC instead.
   */
  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParams);
    const fd = VpnRpc.readTunFd(want);
    if (fd > 0) {
      VpnLog.info('the tun descriptor has been delivered through the want: ' + fd);
    }
  }

  private async handleVpnMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    const bridge = VpnUiBridge.getInstance();
    switch (call.method) {
      case VpnRpc.METHOD_PREPARE:
        // The core lives in this process, so keep the process awake before the
        // tunnel starts carrying traffic.
        await this.startContinuousTask();
        try {
          const fd = await bridge.prepare();
          this.vpnActive = true;
          this.rememberCurrentNetwork();
          result.success(fd);
        } catch (error) {
          this.vpnActive = false;
          await this.stopContinuousTask();
          result.error(
            'VPN_PREPARE_FAILED',
            'failed to start the vpn extension: ' + JSON.stringify(error),
            null,
          );
        }
        break;
      case VpnRpc.METHOD_STOP:
        this.vpnActive = false;
        await bridge.stop();
        await this.stopContinuousTask();
        result.success(null);
        break;
      default:
        result.notImplemented();
        break;
    }
  }
}
