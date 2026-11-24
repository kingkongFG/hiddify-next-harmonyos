import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core_providers.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/domain/failures.dart';
import 'package:hiddify/features/common/active_profile/active_profile_notifier.dart';
import 'package:hiddify/features/common/active_profile/has_any_profile_notifier.dart';
import 'package:hiddify/features/common/common.dart';
import 'package:hiddify/features/home/widgets/widgets.dart';
import 'package:hiddify/features/profiles/view/share_profile_sheet.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  static int _diagCount = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    // OHOS adapt: the Scaffold used to wrap the scroll view in a `Stack` that
    // had exactly one child and a `bottomCenter` alignment. That is dead
    // weight upstream, but on the HarmonyOS embedder a loose-constrained
    // single-child Stack can collapse the viewport to zero height, which
    // renders the whole home page - app bar and "+" action included - as an
    // empty surface. The scroll view is the only child, so it can be used
    // directly.
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_diagCount < 5) {
            _diagCount++;
            final mq = MediaQuery.maybeOf(context);
            print(
              '[DIAG] HomePage constraints=$constraints '
              'mqSize=${mq?.size} mqPadding=${mq?.padding} '
              'mqViewPadding=${mq?.viewPadding} '
              'mqViewInsets=${mq?.viewInsets} dpr=${mq?.devicePixelRatio} '
              'hasAnyProfile=${hasAnyProfile.runtimeType} '
              'activeProfile=${activeProfile.runtimeType}',
            );
          }
          return CustomScrollView(
            slivers: [
              NestedTabAppBar(
                title: Row(
                  children: [
                    Text(t.general.appTitle),
                    const Gap(4),
                    const AppVersionLabel(),
                  ],
                ),
                actions: [
                  if (activeProfile case AsyncData(value: final current?))
                    IconButton(
                      onPressed: () => ShareProfileSheet.show(context, current),
                      icon: const Icon(Icons.share),
                      tooltip: t.general.share,
                    ),
                  IconButton(
                    onPressed: () => const AddProfileRoute().push(context),
                    icon: const Icon(Icons.add_circle),
                    tooltip: t.profile.add.buttonText,
                  ),
                ],
              ),
              switch (activeProfile) {
                AsyncData(value: final profile?) => MultiSliver(
                    children: [
                      ProfileTile(profile: profile, isMain: true),
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 8,
                            right: 8,
                            top: 8,
                            bottom: 86,
                          ),
                          child: ConnectionButton(),
                        ),
                      ),
                    ],
                  ),
                AsyncData() => switch (hasAnyProfile) {
                    AsyncData(value: true) =>
                      const EmptyActiveProfileHomeBody(),
                    _ => const EmptyProfilesHomeBody(),
                  },
                AsyncError(:final error) =>
                  SliverErrorBodyPlaceholder(t.presentShortError(error)),
                _ => const SliverToBoxAdapter(),
              },
            ],
          );
        },
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.about.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 1,
        ),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
