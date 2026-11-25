import 'dart:async';

import 'package:combine/combine.dart';
import 'package:dartx/dartx.dart';
import 'package:hiddify/core/prefs/prefs.dart';
import 'package:hiddify/data/data_providers.dart';
import 'package:hiddify/domain/connectivity/connectivity.dart';
import 'package:hiddify/domain/core_service_failure.dart';
import 'package:hiddify/domain/singbox/singbox.dart';
import 'package:hiddify/features/common/connectivity/connectivity_controller.dart';
import 'package:hiddify/utils/pref_notifier.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proxies_notifier.g.dart';

enum ProxiesSort {
  unsorted,
  name,
  delay;

  String present(TranslationsEn t) => switch (this) {
        ProxiesSort.unsorted => t.proxies.sortOptions.unsorted,
        ProxiesSort.name => t.proxies.sortOptions.name,
        ProxiesSort.delay => t.proxies.sortOptions.delay,
      };
}

@Riverpod(keepAlive: true)
class ProxiesSortNotifier extends _$ProxiesSortNotifier {
  late final _pref = Pref(
    ref.watch(sharedPreferencesProvider),
    "proxies_sort_mode",
    ProxiesSort.unsorted,
    mapFrom: ProxiesSort.values.byName,
    mapTo: (value) => value.name,
  );

  @override
  ProxiesSort build() => _pref.getValue();

  Future<void> update(ProxiesSort value) {
    state = value;
    return _pref.update(value);
  }
}

@riverpod
class ProxiesNotifier extends _$ProxiesNotifier with AppLogger {
  @override
  Stream<List<OutboundGroup>> build() async* {
    ref.disposeDelay(const Duration(seconds: 15));
    ref.listen(connectivityControllerProvider, (previous, next) {
      final wasConnected = previous?.valueOrNull is Connected;
      if (next case AsyncData(value: Connected())) {
        if (!wasConnected) unawaited(autoSelectFastest());
      }
    });
    final serviceRunning = await ref.watch(serviceRunningProvider.future);
    if (!serviceRunning) {
      throw const CoreServiceNotRunning();
    }
    // A provider created *after* the tunnel came up never observes a fresh
    // `Connected` transition, so the listener above never fires and the home
    // screen stayed without any latency. Kick a selection off for the current
    // state as well.
    if (ref.read(connectivityControllerProvider).valueOrNull is Connected) {
      unawaited(autoSelectFastest());
    }
    final sortBy = ref.watch(proxiesSortNotifierProvider);
    yield* ref
        .watch(coreFacadeProvider)
        .watchOutbounds()
        .map(
          (event) => event.getOrElse(
            (err) {
              loggy.warning("error receiving proxies", err);
              throw err;
            },
          ),
        )
        .asyncMap((proxies) async => _sortOutbounds(proxies, sortBy));
  }

  Future<List<OutboundGroup>> _sortOutbounds(
    List<OutboundGroup> outbounds,
    ProxiesSort sortBy,
  ) async {
    return CombineWorker().execute(
      () {
        final sortedOutbounds = <OutboundGroup>[];
        for (final group in outbounds) {
          final items = switch (sortBy) {
            ProxiesSort.name => group.items.sortedBy((e) => e.tag),
            ProxiesSort.delay => group.items.sortedWith((a, b) {
                final ai = a.urlTestDelay;
                final bi = b.urlTestDelay;
                if (ai == 0 && bi == 0) return -1;
                if (ai == 0 && bi > 0) return 1;
                if (ai > 0 && bi == 0) return -1;
                if (ai == bi && a.type.isGroup) return -1;
                return ai.compareTo(bi);
              }),
            ProxiesSort.unsorted => group.items,
          };
          sortedOutbounds.add(group.copyWith(items: items));
        }
        return sortedOutbounds;
      },
    );
  }

  Future<void> changeProxy(String groupTag, String outboundTag) async {
    loggy.debug(
      "changing proxy, group: [$groupTag] - outbound: [$outboundTag]",
    );
    if (state case AsyncData(value: final outbounds)) {
      await ref
          .read(coreFacadeProvider)
          .selectOutbound(groupTag, outboundTag)
          .getOrElse((err) {
        loggy.warning("error selecting outbound", err);
        throw err;
      }).run();
      state = AsyncData(
        [
          ...outbounds.map(
            (e) => e.tag == groupTag ? e.copyWith(selected: outboundTag) : e,
          ),
        ],
      ).copyWithPrevious(state);
    }
  }

  Future<void> urlTest(String groupTag) async {
    loggy.debug("testing group: [$groupTag]");
    if (state case AsyncData()) {
      await ref.read(coreFacadeProvider).urlTest(groupTag).getOrElse((err) {
        loggy.error("error testing group", err);
        throw err;
      }).run();
    }
  }

  bool _autoSelecting = false;

  /// Picks the lowest-latency node of every selector group once the tunnel is
  /// up, so a fresh connection does not silently stay on a dead node.
  ///
  /// `urlTestDelay` only refreshes through the outbound event stream, hence
  /// the wait after triggering the test before a node is picked.
  Future<void> autoSelectFastest() async {
    if (_autoSelecting) return;
    _autoSelecting = true;
    try {
      final groups = await _waitForOutbounds();
      if (groups == null || groups.isEmpty) return;
      final selectors =
          groups.where((group) => group.type == ProxyType.selector).toList();
      if (selectors.isEmpty) return;
      loggy.info("auto selecting fastest node for ${selectors.length} group(s)");
      for (final group in selectors) {
        try {
          await urlTest(group.tag);
        } catch (e) {
          loggy.warning("url test failed for [${group.tag}]", e);
        }
      }
      final updated =
          await _waitForDelays(selectors.map((g) => g.tag).toSet()) ??
              state.valueOrNull ??
              groups;
      for (final group in updated.where((g) => g.type == ProxyType.selector)) {
        final candidates = group.items
            .where(
              (item) =>
                  item.type != ProxyType.selector &&
                  item.type != ProxyType.urltest &&
                  item.urlTestDelay > 0,
            )
            .toList();
        if (candidates.isEmpty) continue;
        candidates.sort((a, b) => a.urlTestDelay.compareTo(b.urlTestDelay));
        final best = candidates.first;
        if (best.tag == group.selected) continue;
        loggy.info(
          "auto selected [${best.tag}] (${best.urlTestDelay}ms) in [${group.tag}]",
        );
        await changeProxy(group.tag, best.tag);
      }
    } finally {
      _autoSelecting = false;
    }
  }

  /// urlTest results arrive asynchronously through the outbound event stream,
  /// so a fixed wait either decides on all-zero delays or gives up too early.
  /// Poll until every requested selector reports at least one latency.
  Future<List<OutboundGroup>?> _waitForDelays(
    Set<String> groupTags, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final groups = state.valueOrNull;
      if (groups == null) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        continue;
      }
      final pending = groups.where(
        (g) =>
            groupTags.contains(g.tag) &&
            !g.items.any(
              (item) =>
                  item.type != ProxyType.selector &&
                  item.type != ProxyType.urltest &&
                  item.urlTestDelay > 0,
            ),
      );
      if (pending.isEmpty) return groups;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return state.valueOrNull;
  }

  Future<List<OutboundGroup>?> _waitForOutbounds() async {
    for (var i = 0; i < 20; i++) {
      final groups = state.valueOrNull;
      if (groups != null && groups.isNotEmpty) return groups;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return state.valueOrNull;
  }
}
