import pasteboard from '@ohos.pasteboard';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import type Want from '@ohos.app.ability.Want';
import { systemShare } from '@kit.ShareKit';
import { VpnLog } from '../vpn/VpnLog';

const READ_PASTEBOARD_PERMISSION: Permissions = 'ohos.permission.READ_PASTEBOARD';

/**
 * HarmonyOS platform services that the Dart side cannot reach through the
 * Flutter plugin ecosystem.
 *
 *  - `share_plus` ships no `ohos` implementation, so system sharing has to be
 *    driven from ArkTS (ShareKit, with an implicit Want as a fallback).
 *  - Flutter's own `Clipboard.getData` goes through the engine's
 *    PlatformPlugin, which first calls
 *    `requestPermissionsFromUser(['ohos.permission.READ_PASTEBOARD'])`. When
 *    the permission is not declared in module.json5 the request returns
 *    `INVALID_REQ` and the engine replies with `null`, so "add from clipboard"
 *    always received an empty string. Reading the pasteboard here gives the
 *    app a second, independent path (and lets us read HTML/URI records too).
 */
/** Channel constants shared with the Dart side. */
export class OhosPlatformRpc {
  static readonly CHANNEL: string = 'com.hiddify.app/ohos.platform';
  static readonly METHOD_READ_CLIPBOARD: string = 'readClipboard';
  static readonly METHOD_WRITE_CLIPBOARD: string = 'writeClipboard';
  static readonly METHOD_SHARE_TEXT: string = 'shareText';
  static readonly ARG_TEXT: string = 'text';
  static readonly ARG_TITLE: string = 'title';
}

export class OhosPlatformService {
  private static instance: OhosPlatformService | undefined = undefined;

  private context: common.UIAbilityContext | undefined = undefined;

  static getInstance(): OhosPlatformService {
    if (OhosPlatformService.instance === undefined) {
      OhosPlatformService.instance = new OhosPlatformService();
    }
    return OhosPlatformService.instance;
  }

  setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
   * Asks the user for the pasteboard read permission. Since API 12 the
   * pasteboard service rejects `getData()` with error 201 unless the app holds
   * it. The engine asks for the same permission itself, but doing it here keeps
   * the native path independent of whether Flutter's PlatformPlugin ran first.
   */
  private async ensurePasteboardPermission(): Promise<void> {
    const ctx = this.context;
    if (ctx === undefined) {
      return;
    }
    try {
      const manager = abilityAccessCtrl.createAtManager();
      const permissions: Permissions[] = [READ_PASTEBOARD_PERMISSION];
      // The ArkTS declaration exposes both a callback and a promise overload;
      // the callback form avoids the `void & Promise<...>` inference issue.
      await new Promise<void>((resolve): void => {
        manager.requestPermissionsFromUser(
          ctx,
          permissions,
          (error, result): void => {
            if (error) {
              VpnLog.warn('pasteboard permission denied: ' + JSON.stringify(error));
            } else {
              const granted =
                result.authResults.length > 0 && result.authResults[0] === 0;
              VpnLog.info('pasteboard permission result: ' + granted);
            }
            resolve();
          },
        );
      });
    } catch (error) {
      VpnLog.warn('pasteboard permission request failed: ' + JSON.stringify(error));
    }
  }

  /** Reads plain text from the system pasteboard, including HTML/URI records. */
  async readClipboardText(): Promise<string> {
    await this.ensurePasteboardPermission();
    try {
      const board = pasteboard.getSystemPasteboard();
      const data = await board.getData();
      const primary = data.getPrimaryText();
      if (primary !== undefined && primary !== null && primary.length > 0) {
        return primary;
      }

      let collected = '';
      const count = data.getRecordCount();
      for (let i = 0; i < count; i++) {
        const record = data.getRecord(i);
        if (record.mimeType === pasteboard.MIMETYPE_TEXT_PLAIN) {
          collected += record.plainText ?? '';
        } else if (record.mimeType === pasteboard.MIMETYPE_TEXT_HTML) {
          collected += OhosPlatformService.stripHtml(record.htmlText ?? '');
        } else if (record.mimeType === pasteboard.MIMETYPE_TEXT_URI) {
          collected += record.uri ?? '';
        }
      }
      return collected;
    } catch (error) {
      VpnLog.warn('readClipboardText failed: ' + JSON.stringify(error));
      return '';
    }
  }

  /** Writes plain text to the system pasteboard. No permission is required. */
  async writeClipboardText(text: string): Promise<boolean> {
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      await pasteboard.getSystemPasteboard().setData(data);
      return true;
    } catch (error) {
      VpnLog.warn('writeClipboardText failed: ' + JSON.stringify(error));
      return false;
    }
  }

  /**
   * Opens the system share sheet for a piece of text.
   * ShareKit is the modern API; the implicit `sendData` Want is kept as a
   * fallback for builds where the share kit is unavailable. Returns false when
   * neither could be started so the caller can copy the text instead.
   */
  async shareText(text: string, title: string): Promise<boolean> {
    const ctx = this.context;
    if (ctx === undefined) {
      return false;
    }
    if (await this.shareWithShareKit(ctx, text, title)) {
      return true;
    }
    return await this.shareWithWant(ctx, text);
  }

  private async shareWithShareKit(
    ctx: common.UIAbilityContext,
    text: string,
    title: string,
  ): Promise<boolean> {
    try {
      const record: systemShare.SharedRecord = {
        utd: 'general.plain-text',
        content: text,
        title: title,
        description: title,
      };
      const data = new systemShare.SharedData(record);
      const controller = new systemShare.ShareController(data);
      const options: systemShare.ShareControllerOptions = {};
      await controller.show(ctx, options);
      VpnLog.info('system share sheet opened');
      return true;
    } catch (error) {
      VpnLog.warn('share kit failed: ' + JSON.stringify(error));
      return false;
    }
  }

  private async shareWithWant(ctx: common.UIAbilityContext, text: string): Promise<boolean> {
    try {
      const want: Want = {
        action: 'ohos.want.action.sendData',
        type: 'text/plain',
        parameters: {
          'ability.want.params.TEXT': text,
        },
      };
      await ctx.startAbility(want);
      VpnLog.info('share want started');
      return true;
    } catch (error) {
      VpnLog.warn('share want failed: ' + JSON.stringify(error));
      return false;
    }
  }

  private static stripHtml(html: string): string {
    return html
      .replace(/<br\s*\/?>/gi, '\n')
      .replace(/<\/p>/gi, '\n')
      .replace(/<[^>]*>/g, '')
      .replace(/&nbsp;/gi, ' ')
      .replace(/&amp;/gi, '&')
      .replace(/&lt;/gi, '<')
      .replace(/&gt;/gi, '>')
      .replace(/&quot;/gi, '"')
      .replace(/&#39;/gi, "'");
  }
}
