import 'dart:convert';

import 'package:hiddify/domain/singbox/singbox.dart';
import 'package:hiddify/utils/validators.dart';

typedef ProfileLink = ({String url, String name});

// TODO: test and improve
abstract class LinkParser {
  // protocols schemas
  static const protocols = {'clash', 'clashmeta', 'sing-box', 'hiddify'};
  static const rawProtocols = {
    'ss',
    'vmess',
    'vless',
    'trojan',
    'tuic',
    'hysteria2',
    'hy2',
    'ssh',
    // OHOS adapt: the official Hiddify protocol stack also lists
    // WireGuard, NaiveProxy and ShadowTLS, so those link schemes are
    // recognised as proxy links as well.
    'wg',
    'naive',
    'shadowtls',
  };

  static ProfileLink? parse(String link) {
    return simple(link) ?? deep(link);
  }

  static ProfileLink? simple(String link) {
    if (!isUrl(link)) return null;
    final uri = Uri.parse(link.trim());
    // OHOS adapt: the name of a shared subscription lives in the URL fragment
    // ("https://host/path?token=x#Node Name"), while upstream only looked at
    // the "name" query parameter. Android's share sheet and the Chinese
    // providers both use the fragment form, so read it as a fallback.
    final name = uri.queryParameters['name'] ??
        (uri.hasFragment ? Uri.decodeComponent(uri.fragment) : '') ??
        '';
    return (
      url: uri.toString(),
      name: name,
    );
  }

  /// Extracts the first URL-looking token out of a free-form text.
  ///
  /// The Android share sheet and most IM apps copy a whole chat message, so
  /// the clipboard may contain a title line followed by the actual link.
  /// Upstream only accepted the raw URL, which made "add from clipboard" fail
  /// for anything that was not copied verbatim.
  static ProfileLink? fromText(String text) {
    final trimmed = text.trim();
    final direct = parse(trimmed);
    if (direct != null) return direct;

    for (final line in trimmed.split(RegExp(r'[\r\n]'))) {
      final candidate = line.trim();
      if (candidate.isEmpty) continue;
      final parsed = parse(candidate);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static ({String content, String name})? protocol(String content) {
    final lines = safeDecodeBase64(content).split('\n');
    for (final line in lines) {
      final uri = Uri.tryParse(line);
      if (uri == null) continue;
      final fragment =
          uri.hasFragment ? Uri.decodeComponent(uri.fragment) : null;
      final name = switch (uri.scheme) {
        'ss' => fragment ?? ProxyType.shadowsocks.label,
        'vmess' => ProxyType.vmess.label,
        'vless' => fragment ?? ProxyType.vless.label,
        'trojan' => fragment ?? ProxyType.trojan.label,
        'tuic' => fragment ?? ProxyType.tuic.label,
        'hy2' || 'hysteria2' => fragment ?? ProxyType.hysteria.label,
        'ssh' => fragment ?? ProxyType.ssh.label,
        // OHOS adapt: WireGuard / NaiveProxy / ShadowTLS links.
        'wg' => fragment ?? ProxyType.wireguard.label,
        'naive' => fragment ?? ProxyType.naive.label,
        'shadowtls' => fragment ?? ProxyType.shadowtls.label,
        _ => null,
      };
      if (name != null) {
        return (content: content, name: name);
      }
    }
    return null;
  }

  static ProfileLink? deep(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    final queryParams = uri.queryParameters;
    switch (uri.scheme) {
      case 'clash' || 'clashmeta' when uri.authority == 'install-config':
        if (uri.authority != 'install-config' ||
            !queryParams.containsKey('url')) return null;
        return (url: queryParams['url']!, name: queryParams['name'] ?? '');
      case 'sing-box':
        if (uri.authority != 'import-remote-profile' ||
            !queryParams.containsKey('url')) return null;
        return (url: queryParams['url']!, name: queryParams['name'] ?? '');
      case 'hiddify':
        if ((uri.authority != 'install-config' &&
                uri.authority != 'install-sub') ||
            !queryParams.containsKey('url')) return null;
        return (url: queryParams['url']!, name: queryParams['name'] ?? '');
      default:
        return null;
    }
  }
}

String safeDecodeBase64(String str) {
  try {
    return utf8.decode(base64Decode(str));
  } catch (e) {
    return str;
  }
}
