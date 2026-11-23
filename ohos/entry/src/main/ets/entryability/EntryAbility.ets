
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
import type Want from '@ohos.app.ability.Want';
import process from '@ohos.process';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
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
          result.success(fd);
        } catch (error) {
          await this.stopContinuousTask();
          result.error(
            'VPN_PREPARE_FAILED',
            'failed to start the vpn extension: ' + JSON.stringify(error),
            null,
          );
        }
        break;
      case VpnRpc.METHOD_STOP:
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
