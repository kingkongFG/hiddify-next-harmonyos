/**
 * Process wide holder for the TUN file descriptor.
 *
 * The VPN extension owns the tunnel device. When it happens to run in the
 * same process as the UI ability, the descriptor is picked up directly from
 * here; otherwise the descriptor is pulled over RPC.
 */
export class VpnTunStore {
  private static tunFd: number = -1;
  private static waiter: ((fd: number) => void) | undefined = undefined;
  private static rejecter: ((reason: string) => void) | undefined = undefined;

  /** Remembers the descriptor of the freshly created TUN device. */
  static setFd(fd: number): void {
    VpnTunStore.tunFd = fd;

    const waiter = VpnTunStore.waiter;
    if (waiter) {
      VpnTunStore.waiter = undefined;
      VpnTunStore.rejecter = undefined;
      waiter(fd);
    }
  }

  /** Returns the parked descriptor, or -1 when no TUN exists yet. */
  static getFd(): number {
    return VpnTunStore.tunFd;
  }

  /** Forgets the descriptor, e.g. after the tunnel has been destroyed. */
  static clear(): void {
    VpnTunStore.tunFd = -1;
  }

  /**
   * Waits until the descriptor of the TUN device shows up.
   *
   * Resolves immediately when the device already exists, otherwise it waits
   * for `setFd` to be called.
   */
  static awaitFd(timeoutMs: number): Promise<number> {
    if (VpnTunStore.tunFd > 0) {
      return Promise.resolve(VpnTunStore.tunFd);
    }

    return new Promise<number>((resolve, reject) => {
      VpnTunStore.waiter = resolve;
      VpnTunStore.rejecter = reject;

      setTimeout(() => {
        if (VpnTunStore.waiter === resolve) {
          VpnTunStore.waiter = undefined;
          VpnTunStore.rejecter = undefined;
          reject(new Error('timed out while waiting for the tun device'));
        }
      }, timeoutMs);
    });
  }
}
