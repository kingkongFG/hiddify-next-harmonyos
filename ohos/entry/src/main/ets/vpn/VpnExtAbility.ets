import { VpnExtensionAbility } from '@kit.NetworkKit';
import { rpc } from '@kit.IPCKit';
import type Want from '@ohos.app.ability.Want';
import { VpnLog } from './VpnLog';
import { VpnRpc } from './VpnRpc';
import { VpnTunStore } from './VpnTunStore';
import { createTunDevice, destroyTunDevice } from './VpnTunFactory';

/**
 * RPC endpoint of the VPN extension process.
 *
 * The UI process cannot read the TUN descriptor on its own: the descriptor is
 * created by the VPN service and is only valid inside the process that asked
 * for it. Writing it into a reply parcel makes the IPC layer duplicate it,
 * so the UI process ends up with a descriptor of its own.
 */
class VpnExtStub extends rpc.RemoteObject {
  private owner: VpnExtAbility;

  constructor(owner: VpnExtAbility) {
    super('com.hiddify.harmony.vpnext');
    this.owner = owner;
  }

  /**
   * NOTE: this callback must answer *synchronously*.
   *
   * Returning `true` makes the IPC layer send the reply parcel straight away.
   * An earlier version kicked off an async `deliverTunFd(reply)` and returned
   * immediately, so the UI process always received an empty parcel
   * (`1900010 Failed to read data from the message sequence`) even though the
   * TUN device had already been created. Writing the descriptor inline keeps
   * the parcel and the reply in sync; the UI polls until the device exists.
   */
  onRemoteMessageRequest(
    code: number,
    data: rpc.MessageSequence,
    reply: rpc.MessageSequence,
    options: rpc.MessageOption,
  ): boolean {
    if (code === VpnRpc.CODE_GET_TUN_FD) {
      // The framework sends the reply using this very option. It therefore has
      // to advertise that a descriptor may be attached; otherwise the IPC
      // layer strips the fd from the outgoing parcel and the UI process only
      // sees an empty reply (1900010).
      options.setFlags(rpc.MessageOption.TF_ACCEPT_FDS);
      this.owner.deliverTunFd(reply);
      return true;
    }
    return true;
  }
}

/**
 * The HarmonyOS VPN Extension.
 *
 * It owns the tunnel device: the system creates the virtual NIC when the
 * extension asks for it and hands back the descriptor. The Go core on the
 * other hand lives in the UI process next to the Flutter engine, therefore
 * the descriptor is shipped over RPC on request.
 */
export default class VpnExtAbility extends VpnExtensionAbility {
  onCreate(want: Want): void {
    VpnLog.info('VpnExtAbility.onCreate, want parameters: ' + JSON.stringify(want.parameters));
    this.createTun();
  }

  onDestroy(): void {
    VpnLog.info('VpnExtAbility.onDestroy');
    VpnTunStore.clear();
    destroyTunDevice();
  }

  /**
   * The UI process connects to this ability in order to pull the descriptor.
   */
  onConnect(want: Want): rpc.RemoteObject {
    VpnLog.info('VpnExtAbility.onConnect');
    return new VpnExtStub(this);
  }

  /** Creates the tunnel device owned by the system. */
  private async createTun(): Promise<void> {
    try {
      const fd = await createTunDevice(this.context);
      VpnTunStore.setFd(fd);
    } catch (error) {
      VpnLog.error('failed to create the tun device: ' + JSON.stringify(error));
    }
  }

  /**
   * Writes the descriptor into the reply parcel of the UI process.
   *
   * Runs synchronously inside `onRemoteMessageRequest`, see the note on
   * `VpnExtStub`. When the tunnel is still being created it parks a marker so
   * the UI can retry a moment later.
   */
  deliverTunFd(reply: rpc.MessageSequence): void {
    const fd = VpnTunStore.getFd();
    if (fd <= 0) {
      reply.writeString(VpnRpc.ERROR_NOT_READY);
      return;
    }
    const sizeBefore = reply.getSize();
    try {
      reply.writeFileDescriptor(fd);
      VpnLog.info(
        'the tun descriptor has been written into the reply parcel: ' + fd +
        ', size ' + sizeBefore + ' -> ' + reply.getSize() +
        ', containsFd ' + reply.containFileDescriptors(),
      );
    } catch (error) {
      VpnLog.error('failed to write the tun descriptor: ' + JSON.stringify(error));
      reply.writeString(VpnRpc.ERROR_WRITE_FAILED);
    }
  }
}
