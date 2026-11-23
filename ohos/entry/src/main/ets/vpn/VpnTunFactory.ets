import { vpnExtension } from '@kit.NetworkKit';
import type { VpnExtensionContext } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { VpnLog } from './VpnLog';
import { VpnRpc } from './VpnRpc';
import { VpnTunStore } from './VpnTunStore';
import { buildTunConfig } from './VpnTunConfig';

/** The connection of the currently running tunnel, if any. */
let connection: vpnExtension.VpnConnection | undefined = undefined;

/**
 * Creates the TUN device owned by the system.
 *
 * The virtual NIC is created by the NetManager VPN service, which hands the
 * descriptor of the resulting device back to the calling process. The
 * descriptor is only meaningful inside this process, which is why it has to
 * be shipped to the UI process before the Go core can use it.
 */
export async function createTunDevice(context: common.ExtensionContext): Promise<number> {
  const vpnContext = context as VpnExtensionContext;
  const conn = vpnExtension.createVpnConnection(vpnContext);
  const fd = await conn.create(buildTunConfig(VpnRpc.BUNDLE_NAME));
  VpnLog.info('the tun device has been created, fd = ' + fd);

  // Park the descriptor before anything else can fail. `protectProcessNet`
  // used to run first and a rejection there discarded a perfectly good tunnel,
  // leaving the UI polling a descriptor that would never arrive.
  VpnTunStore.setFd(fd);
  connection = conn;

  // Keep the application's own sockets off the tunnel, otherwise the outbound
  // proxy connections would be routed back into the tunnel.
  try {
    await conn.protectProcessNet();
    VpnLog.info('the process network has been protected');
  } catch (error) {
    VpnLog.warn('protectProcessNet failed: ' + JSON.stringify(error));
  }

  return fd;
}

/** Tears the tunnel device down again. */
export async function destroyTunDevice(): Promise<void> {
  const conn = connection;
  connection = undefined;
  if (!conn) {
    return;
  }
  try {
    await conn.destroy();
    VpnLog.info('the tun device has been destroyed');
  } catch (error) {
    VpnLog.warn('failed to destroy the tun device: ' + JSON.stringify(error));
  }
}
