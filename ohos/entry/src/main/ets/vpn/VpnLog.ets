import { hilog } from '@kit.PerformanceAnalysisKit';
import process from '@ohos.process';

/**
 * Diagnostic logging for the VPN bridge.
 *
 * The extension abilities live in their own process, and `console.*` output
 * produced there is not reliably attributed to that process in `hilog`. Every
 * message therefore goes through `hilog` with a dedicated tag, which makes the
 * whole VPN trace greppable with a single command:
 *
 *   hilog | grep HiddifyVPN
 *
 * The process id is part of every line: the TUN descriptor has to cross a
 * process boundary, so it is essential to know which process produced which
 * line.
 */
const DOMAIN: number = 0xd002000;
const TAG: string = 'HiddifyVPN';

export class VpnLog {
  static info(message: string): void {
    hilog.info(DOMAIN, TAG, '[%{public}d] %{public}s', process.pid, message);
  }

  static warn(message: string): void {
    hilog.warn(DOMAIN, TAG, '[%{public}d] %{public}s', process.pid, message);
  }

  static error(message: string): void {
    hilog.error(DOMAIN, TAG, '[%{public}d] %{public}s', process.pid, message);
  }
}
