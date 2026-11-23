import { vpnExtension } from '@kit.NetworkKit';

/**
 * Builds the TUN configuration handed to the system.
 *
 * The addresses and the MTU have to match the sing-box TUN inbound that the
 * Go core builds (see shared/config.go: inet4 172.19.0.1/28, inet6
 * fdfe:dcba:9876::1/126). Because the virtual NIC is created by the system,
 * sing-box cannot configure the interface itself.
 *
 * @param bundleName Bundle of this application. Its own traffic has to stay
 *                   on the physical network, otherwise the outbound proxy
 *                   connections would be routed back into the tunnel.
 */
export function buildTunConfig(bundleName: string): vpnExtension.VpnConfig {
  return {
    // OHOS adapt: sing-box runs with ipv6-mode = ipv4_only, so its TUN inbound
    // binds 172.19.0.1/28 only and the lwip stack has no IPv6 handler. If an
    // IPv6 address and a ::/0 route are advertised here, every IPv6 flow of
    // every application is routed into the tunnel only to be dropped there,
    // and dual-stack clients keep waiting on the dead path.
    addresses: [
      {
        address: { address: '172.19.0.1', family: 1 },
        prefixLength: 28,
      },
    ],
    routes: [
      {
        interface: 'vpn-tun',
        destination: {
          address: { address: '0.0.0.0', family: 1 },
          prefixLength: 0,
        },
        gateway: { address: '0.0.0.0', family: 1 },
        hasGateway: false,
        isDefaultRoute: true,
      },
    ],
    // DNS queries are sent to the TUN address so that they are captured by the
    // tunnel and answered by sing-box's DNS module (the route rules sniff them
    // as DNS and hand them over to "dns-out").
    dnsAddresses: ['172.19.0.1'],
    mtu: 1500,
    isIPv4Accepted: true,
    isIPv6Accepted: false,
    isBlocking: false,
    isInternal: false,
    blockedApplications: [bundleName],
  };
}
