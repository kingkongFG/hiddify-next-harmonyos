import type Want from '@ohos.app.ability.Want';

/**
 * The shape HarmonyOS uses for a file descriptor that is carried inside
 * `Want.parameters`. The official Want reference documents the fixed form
 * `{ type: 'FD', value: fd }`.
 */
export interface VpnFdCarrier {
  type: string;
  value: number;
}

/**
 * Shared constants for the HarmonyOS VPN bridge.
 *
 * The VPN Extension runs in its own process (`com.hiddify.harmony:vpn`), while
 * the Go core lives in the UI process together with the Flutter/Dart side.
 * The TUN file descriptor therefore has to travel from the VPN process back
 * into the UI process.
 *
 * `rpc.MessageSequence.writeFileDescriptor` is the only mechanism on
 * HarmonyOS that duplicates a descriptor into another process, so the VPN
 * extension exposes an RPC endpoint and the UI process pulls the descriptor
 * out of the reply parcel.
 */
export class VpnRpc {
  /** Bundle name of this application. */
  static readonly BUNDLE_NAME: string = 'com.hiddify.harmony';

  /** Name of the VPN extension ability (type "vpn"). */
  static readonly VPN_ABILITY_NAME: string = 'VpnExtAbility';

  /** Name of the UI ability that hosts the Flutter engine. */
  static readonly UI_ABILITY_NAME: string = 'EntryAbility';

  /** Key used to carry the TUN descriptor inside `Want.parameters`. */
  static readonly KEY_TUN_FD: string = 'hiddify_tun_fd';

  /** The marker the platform uses for descriptor valued parameters. */
  static readonly FD_TYPE: string = 'FD';

  /** RPC code used to ask the extension process for the TUN descriptor. */
  static readonly CODE_GET_TUN_FD: number = 1;

  /** Error marker written into the reply parcel when no TUN exists. */
  static readonly ERROR_NO_TUN_FD: string = 'no-tun-fd';

  /**
   * Marker the extension writes when the TUN device has not been created yet.
   * The UI process retries instead of failing, because the system may finish
   * spinning up the tunnel a little later than the RPC channel.
   */
  static readonly ERROR_NOT_READY: string = 'not-ready';

  /** Marker used when the descriptor itself could not be written. */
  static readonly ERROR_WRITE_FAILED: string = 'write-failed';

  /** Method channel the Dart side uses to drive the VPN extension. */
  static readonly CHANNEL: string = 'com.hiddify.app/ohos.vpn';

  /** Method that starts the VPN extension and awaits the TUN descriptor. */
  static readonly METHOD_PREPARE: string = 'prepare';

  /** Method that tears the VPN extension down. */
  static readonly METHOD_STOP: string = 'stop';

  /** Native -> Dart event emitted when the default physical network changes. */
  static readonly METHOD_NETWORK_CHANGED: string = 'onNetworkChanged';

  /** Builds the parameter object that transports a descriptor. */
  static makeFdCarrier(fd: number): VpnFdCarrier {
    const carrier: VpnFdCarrier = { type: VpnRpc.FD_TYPE, value: fd };
    return carrier;
  }

  /**
   * Reads the TUN descriptor out of an incoming want.
   *
   * Since API 15 the platform exposes descriptors through `want.fds`; older
   * builds keep the `{ type: 'FD', value: fd }` object inside
   * `want.parameters`. Both are checked, the newer one first.
   */
  static readTunFd(want: Want): number {
    const fds = want.fds;
    if (fds) {
      const fd = fds[VpnRpc.KEY_TUN_FD];
      if (typeof fd === 'number' && fd > 0) {
        return fd;
      }
    }

    const parameters = want.parameters;
    if (!parameters) {
      return -1;
    }
    const raw = parameters[VpnRpc.KEY_TUN_FD];
    if (raw === undefined || raw === null) {
      return -1;
    }
    const carrier = raw as VpnFdCarrier;
    if (typeof carrier.value === 'number' && carrier.value > 0) {
      return carrier.value;
    }
    return -1;
  }
}
