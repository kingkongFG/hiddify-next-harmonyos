import 'package:hiddify/data/data_providers.dart';
import 'package:hiddify/domain/connectivity/connectivity.dart';
import 'package:hiddify/domain/core_facade.dart';
import 'package:hiddify/features/common/active_profile/active_profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'connectivity_controller.g.dart';

@Riverpod(keepAlive: true)
class ConnectivityController extends _$ConnectivityController with AppLogger {
  @override
  Stream<ConnectionStatus> build() {
    ref.listen(
      activeProfileProvider.select((value) => value.asData?.value),
      (previous, next) async {
        if (previous == null) return;
        final shouldReconnect = previous != next;
        if (shouldReconnect) {
          await reconnect(next?.id);
        }
      },
    );
    return _core.watchConnectionStatus().doOnData((event) {
      loggy.info("connection status: ${event.format()}");
    });
  }

  CoreFacade get _core => ref.watch(coreFacadeProvider);

  Future<void> toggleConnection() async {
    if (state case AsyncError()) {
      await _connect();
    } else if (state case AsyncData(:final value)) {
      switch (value) {
        case Disconnected():
          await _connect();
        case Connected():
          await _disconnect();
        default:
          if (_isSwitchingStale) {
            // The status never settled (missing Stopped/Started event).
            // Force a clean stop, then honour whatever the user last wanted.
            final wanted = _desiredConnected;
            loggy.warning("stale status transition, forcing a clean rebuild");
            await _disconnect();
            await Future<void>.delayed(const Duration(milliseconds: 600));
            if (wanted) await _connect();
          } else {
            loggy.warning("switching status, debounce");
          }
      }
    }
  }

  Future<void> reconnect(String? profileId) async {
    // The status is not a reliable gate here: a stale `Connecting`/`AsyncError`
    // state used to skip the reconnect entirely, which is why switching the
    // active profile (or its provider) appeared to do nothing while the tunnel
    // was considered up. Follow the user intent instead.
    if (_desiredConnected || _isConnected()) {
      if (profileId == null) {
        return _disconnect();
      }
      loggy.debug("reconnecting, profile: [$profileId]");
      _desiredConnected = true;
      // A plain core restart() only restarts the Go core. The TUN descriptor
      // that was injected once at connect time is not re-created, so on
      // HarmonyOS the core keeps writing into a dead device and the fresh
      // connection silently fails. Rebuild the whole session instead:
      // stop the core -> let the VPN extension die -> prepare a new TUN ->
      // start the core with the new descriptor.
      await _core.stop().run();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final result = await _core.start(profileId).run();
      if (result.isLeft()) {
        result.mapLeft((err) {
          loggy.warning("error reconnecting", err);
          state = AsyncError(err, StackTrace.current);
          _desiredConnected = false;
        });
      } else {
        _desiredConnected = true;
      }
    }
  }

  Future<void> abortConnection() async {
    if (state case AsyncData(:final value)) {
      switch (value) {
        case Connected() || Connecting():
          loggy.debug("aborting connection");
          await _disconnect();
        default:
      }
    }
  }

  /// Rebuilds the entire tunnel after the default physical network changed.
  ///
  /// A Wi-Fi <-> cellular switch abandons every outbound socket built on the
  /// old network and invalidates the one-shot `protectProcessNet()` call. A
  /// plain `restart()` is not enough: it only restarts the Go core and does
  /// not recreate the TUN, so the new sockets stay unprotected. A full
  /// stop/start destroys and recreates the VPN session on the new network.
  bool _rebuilding = false;

  /// Whether the user wants the tunnel up.
  ///
  /// The status alone is not a reliable trigger: a Wi-Fi <-> cellular switch
  /// makes the core report `Disconnected` on its own, and the rebuild used to
  /// be skipped exactly in that window, so the user stayed offline until a
  /// manual toggle. Remember the intent instead.
  bool _desiredConnected = false;

  /// Set while a connect/disconnect is in flight. HarmonyOS can lose the final
  /// `Stopped` event when the VPN session is torn down underneath the core,
  /// which used to leave the button unresponsive ("switching status, debounce"
  /// forever). Once this timestamp is stale the transition is forced.
  DateTime? _switchingSince;

  static const _switchingTimeout = Duration(seconds: 10);

  bool get _isSwitchingStale {
    final since = _switchingSince;
    return since != null && DateTime.now().difference(since) > _switchingTimeout;
  }

  bool _isConnected() {
    if (state case AsyncData(:final value)) return value is Connected;
    return false;
  }

  Future<void> rebuildAfterNetworkChange() async {
    if (_rebuilding) return;
    if (_desiredConnected || _isConnected()) {
      _rebuilding = true;
      try {
        loggy.info("network changed, rebuilding the VPN tunnel");
        _desiredConnected = true;
        await _core.stop().run();
        // Give the system time to tear the old VPN session down before a new
        // one is requested; otherwise the extension can observe a stale fd.
        await Future<void>.delayed(const Duration(milliseconds: 600));
        final activeProfile = await ref.read(activeProfileProvider.future);
        if (activeProfile == null) return;
        final first = await _core.start(activeProfile.id).run();
        if (first.isLeft()) {
          // The new physical network may still be coming up. Retry once.
          loggy.warning("first rebuild attempt failed, retrying");
          await Future<void>.delayed(const Duration(seconds: 2));
          await _core.start(activeProfile.id).run();
        }
      } finally {
        _rebuilding = false;
      }
    }
  }

  Future<void> _connect() async {
    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile == null) {
      loggy.warning("no active profile, skipping connect");
      return;
    }
    _desiredConnected = true;
    _switchingSince = DateTime.now();
    await _core.start(activeProfile.id).mapLeft((err) {
      loggy.warning("error connecting", err);
      state = AsyncError(err, StackTrace.current);
      _desiredConnected = false;
    }).run();
    _switchingSince = null;
  }

  Future<void> _disconnect() async {
    _desiredConnected = false;
    _switchingSince = DateTime.now();
    await _core.stop().mapLeft((err) {
      loggy.warning("error disconnecting", err);
      state = AsyncError(err, StackTrace.current);
    }).run();
    _switchingSince = null;
  }
}

@Riverpod(keepAlive: true)
Future<bool> serviceRunning(ServiceRunningRef ref) => ref
    .watch(
      connectivityControllerProvider.selectAsync((data) => data.isConnected),
    )
    .onError((error, stackTrace) => false);
