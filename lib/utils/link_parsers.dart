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

  /// Matches a link anywhere inside a free-form text (chat message, share
  /// sheet payload, "title: https://..." and so on).
  ///
  /// Both http(s) subscription URLs and the import schemes used by Hiddify /
  /// Clash / sing-box are covered. The character class deliberately stops at
  /// whitespace, quotes and the brackets Chinese IM apps like to wrap links
  /// in; trailing punctuation is trimmed afterwards.
  static final _linkToken = RegExp(
    r'(?:https?|ftp|clash|clashmeta|sing-box|hiddify|ss|vmess|vless|trojan|tuic|hysteria2|hy2|ssh|wg|naive|shadowtls)://[^\s<>"\u201c\u201d\u2018\u2019\u300c\u300d\u3010\u3011\uff08\uff09]+',
    caseSensitive: false,
  );

  static const _trailingPunctuation = '.,;:!?)]}\u3002\uff0c\uff1b\uff1a\uff01\uff1f\uff09\u300d\u3011\u3001';

  /// Pulls every link-looking token out of arbitrary text, in order.
  static List<String> extractCandidates(String text) {
    final result = <String>[];
    for (final match in _linkToken.allMatches(text)) {
      var token = match.group(0)!;
      while (token.isNotEmpty && _trailingPunctuation.contains(token[token.length - 1])) {
        token = token.substring(0, token.length - 1);
      }
      if (token.isNotEmpty && !result.contains(token)) {
        result.add(token);
      }
    }
    return result;
  }

  /// Extracts the first usable profile link out of a free-form text.
  ///
  /// The Android share sheet and most IM apps copy a whole chat message, so
  /// the clipboard may contain a title line followed by the actual link, or a
  /// label and a link on the same line. Upstream only accepted the raw URL,
  /// which made "add from clipboard" fail for anything not copied verbatim.
  static ProfileLink? fromText(String text) {
    final trimmed = text.trim();
    final direct = parse(trimmed);
    if (direct != null) return direct;

    // Tokens embedded in a sentence come before whole-line matching, because
    // "订阅地址：https://host/path" is one line but not one URL.
    for (final token in extractCandidates(trimmed)) {
      final parsed = parse(token);
      if (parsed != null) return parsed;
    }

    for (final line in trimmed.split(RegExp(r'[\r\n]'))) {
      final candidate = line.trim();
      if (candidate.isEmpty) continue;
      final parsed = parse(candidate);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Plain text that can be handed to `addProfile` after a clipboard read.
  /// Keeps the original payload when it contains raw protocol links (ss://,
  /// vless:// ...), because those are consumed by [protocol] as content.
  static String normalizeClipboardText(String text) => text.trim();

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
