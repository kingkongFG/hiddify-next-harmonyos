import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core_providers.dart';
import 'package:hiddify/domain/profiles/profiles.dart';
import 'package:hiddify/services/ohos_platform_service.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Share actions available for a single profile/subscription group.
///
/// `share_plus` has no HarmonyOS implementation, so the system share sheet is
/// opened through the ArkTS platform bridge, with "copy to clipboard" as a
/// guaranteed fallback.
class ShareProfileSheet extends ConsumerWidget {
  const ShareProfileSheet(this.profile, {super.key});

  final Profile profile;

  static Future<void> show(BuildContext context, Profile profile) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ShareProfileSheet(profile),
    );
  }

  /// Deep link understood by this app's own LinkParser (`hiddify://install-sub`).
  String? get importLink {
    return switch (profile) {
      RemoteProfile(:final url, :final name) =>
        'hiddify://install-sub?url=${Uri.encodeComponent(url)}&name=${Uri.encodeComponent(name)}',
      _ => null,
    };
  }

  String? get subscriptionUrl => switch (profile) {
        RemoteProfile(:final url) => url,
        _ => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final url = subscriptionUrl;
    final link = importLink;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.general.shareProfileTitle,
              style: theme.textTheme.titleLarge,
            ),
            const Gap(4),
            Text(
              profile.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(16),
            if (url == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.primary),
                      const Gap(12),
                      Expanded(child: Text(t.general.noSubscriptionLink)),
                    ],
                  ),
                ),
              )
            else ...[
              _LinkPreview(url: url),
              const Gap(12),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: Text(t.general.systemShare),
                subtitle: Text(t.general.shareViaApp),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  final ok = await OhosPlatformService.instance.shareText(
                    url,
                    title: profile.name,
                  );
                  if (!context.mounted) return;
                  if (!ok) {
                    await OhosPlatformService.instance.copyToClipboard(url);
                    if (context.mounted) {
                      CustomToast.success(t.general.shareUnavailable).show(context);
                    }
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(t.general.copyLink),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  await OhosPlatformService.instance.copyToClipboard(url);
                  if (!context.mounted) return;
                  CustomToast.success(t.general.linkCopied).show(context);
                  Navigator.of(context).pop();
                },
              ),
              if (link != null)
                ListTile(
                  leading: const Icon(Icons.qr_code_2),
                  title: Text(t.general.copyImportLink),
                  subtitle: Text(t.general.importLinkHint),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () async {
                    await OhosPlatformService.instance.copyToClipboard(link);
                    if (!context.mounted) return;
                    CustomToast.success(t.general.linkCopied).show(context);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkPreview extends StatelessWidget {
  const _LinkPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        url,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
