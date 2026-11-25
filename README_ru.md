[**🇺🇸 English**](README.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[**🇨🇳 简体中文**](README_cn.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[**![Lang_farsi](https://user-images.githubusercontent.com/125398461/234186932-52f1fa82-52c6-417f-8b37-08fe9250a55f.png) فارسی**](README_fa.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;


<p align="center"><img src="assets/images/logo.svg" width="168"/></p>

> ### WARNING: Unofficial HarmonyOS (OpenHarmony) port - read this first
>
> This repository is a **fork of [Hiddify-Next](https://github.com/hiddify/hiddify-next) by the Hiddify team**, not an original product. The client design, the Dart/Flutter application code and UI, and the `sing-box` based core all come from the upstream project and its contributors. This repository **only maintains the HarmonyOS adaptation**; the official app lives upstream.
>
> What this fork actually changes:
>
> - A new **ArkTS** native host project under `ohos/`: `EntryAbility`, `VpnExtAbility` (VPN extension ability), `VpnTunFactory` / `VpnTunStore` / `VpnRpc` (TUN device and fd passing), `VpnUiBridge` (Dart to ArkTS channel), `OhosPlatformService` and plugin registration.
> - **The Dart layer is inherited from upstream and is NOT rewritten in ArkTS.** Only the platform/native layer is ArkTS.
> - The Go `sing-box` core is rebuilt for `openharmony/arm64` with the `lwip` network stack and shipped as `ohos/entry/libs/arm64-v8a/libcore.so`.
> - Supported platform: HarmonyOS phone / tablet (arm64, bundle name `com.hiddify.harmony`). HarmonyOS PC (x86_64) is not supported yet.
>
> License: this port inherits the upstream **CC BY-NC-SA 4.0** license. All original copyright remains with the upstream authors. Please report port-specific bugs in **this** repository, not upstream. Full note: [README.md](README.md).

> ### 🤝 Contributing, technical exchange and roadmap
>
> HarmonyOS developers are welcome here. Issues, PRs and plain technical questions about the OpenHarmony adaptation are all appreciated — especially experience with **ArkTS / ArkUI**, the native **VPN / TUN** APIs, native bridging between Dart and ArkTS, and **porting Flutter plugins to OHOS**.
>
> **Roadmap:** an **incremental ArkTS re-implementation rehearsal** — migrating the Dart-layer services and screens onto ArkTS / ArkUI step by step while keeping the current HAP usable. Early input on the migration boundary is especially welcome. Full note: [README.md](README.md).

<div align="center">
    
[![GP-Intalls](https://img.shields.io/endpoint?color=green&logo=google-play&logoColor=green&url=https%3A%2F%2Fplay.cuzi.workers.dev%2Fplay%3Fi%3Dapp.hiddify.com%26l%3DGoogle%2520Play%26m%3D%24shortinstalls&style=flat-square)](https://play.google.com/store/apps/details?id=app.hiddify.com) [![Downloads](https://img.shields.io/github/downloads/hiddify/hiddify-next/total?style=flat-square&logo=github)](https://github.com/hiddify/hiddify-next/releases/)[![Last Version](https://img.shields.io/github/release/hiddify/hiddify-next/all.svg?style=flat-square)](https://github.com/hiddify/hiddify-next/)[![Last Release Date](https://img.shields.io/github/release-date/hiddify/hiddify-next.svg?style=flat-square)](https://github.com/hiddify/hiddify-next/)[![commits](https://img.shields.io/github/commit-activity/m/hiddify/hiddify-next?style=flat-square)](https://github.com/hiddify/hiddify-next/)
[![Youtube](https://img.shields.io/youtube/channel/views/UCxrmeMvVryNfB4XL35lXQNg?label=Youtube&style=flat-square&logo=youtube)](https://www.youtube.com/@hiddify)[![Telegram Channel](https://img.shields.io/endpoint?label=Channel&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify&color=blue)](https://telegram.dog/hiddify)[![Telegram Group](https://img.shields.io/endpoint?color=neon&label=Support%20Group&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify_board)](https://telegram.dog/hiddify_board/5)

</div>

## Что такое Hiddify-Next?
Многоплатформенный клиент на основе [Sing-box](https://github.com/SagerNet/sing-box), который служит универсальным набором инструментов прокси. Это приложение предлагает широкий спектр возможностей, которые перечислены ниже. Он также поддерживает большое количество протоколов. Приложение бесплатное, без рекламы и с открытым исходным кодом. Он предоставляет безопасный и конфиденциальный инструмент для получения доступа к бесплатному Интернету.

Приложение разработано с использованием [Flutter](https://flutter.dev/) и [Go](https://go.dev/). Для получения дополнительной информации вы можете прочитать наши Рекомендации по участию в разработке.

<div align=center>
<img width=90% alt="English Demo" src="https://github.com/hiddify/hiddify-next/assets/125398461/1b592bf9-b19f-4592-b02d-a3fa6216d257">
</div>

## 🚀 Основные особенности
⭐ Простота использования благодаря простому пользовательскому интерфейсу.

✈️ Мультиплатформенность: Android, Windows, Linux и macOS (PR для iOS приветствуются)

🔍 Автоматический выбор по задержке

🟡 Широкий выбор протоколов: ECH, Sing-box, V2ray, Xray, Vless, Vmess, Reality, TUIC, Hysteria, ShadowTLS, SSH, Clash, Clash мета.

🟡 Ссылки на подписку: Clash, Clash мета, Sing-box и Shadowsocks.

🔄 Автоматическое обновление подписки

🔎 Отображать информацию профиля, включая оставшиеся дни и использование трафика.

💻 Совершенно бесплатно, без рекламы и перебоев.

🛡 Открытый исходный код и поддержка сообщества

🌙 Темный и светлый режимы

⚙ Совместим со всеми панелями управления прокси.

⭐ Подходящая конфигурация для Ирана, Китая, России и других стран.

📱 Доступно в [Google Play](https://play.google.com/store/apps/details?id=app.hiddify.com)

## Скачать
<div align=left>
<table>
    <thead align=center>
        <tr>
            <th>Операционная система</th>
            <th>Скачать</th>
        </tr>
    </thead>
    <tbody align=center>
        <tr>
        <td>Андроид</td><td>
            <a href="https://play.google.com/store/apps/details?id=app.hiddify.com"><img width=150px src="https://github.com/hiddify/hiddify-next/blob/main/docs/google-play-badge.png"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-universal.apk"><img src="https://img.shields.io/badge/APK-Universal-044d29.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-arm64.apk"><img src="https://img.shields.io/badge/APK-ArmV8-168039.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-arm7.apk"><img src="https://img.shields.io/badge/APK-ArmV7-45bf55.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-x86_64.apk"><img src="https://img.shields.io/badge/APK-x86_64-96ed89.svg?logo=github"></a>
        </td>
        </tr>
        <tr>
            <td>Окна</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-windows-x64-setup.zip"><img src="https://img.shields.io/badge/Setup-x64-0078d7.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-windows-x64-portable.zip"><img src="https://img.shields.io/badge/Portable-x64-2d7d9a.svg?logo=github"></a>
        </td>
        </tr>
        <tr>
            <td>Мак</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-macos-universal.zip"><img src="https://img.shields.io/badge/DMG-Universal-ea005e.svg?logo=github"></a></td>
        </tr>
        <tr>
            <td>Линукс</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-linux-x64.zip"><img src="https://img.shields.io/badge/AppImage-amd64-f84e29.svg?logo=github"> </a></td>
        </tr>
    </tbody>
</table>

## Благодарности

- [Sing-box](https://github.com/SagerNet/sing-box)
- [Sing-box для Андроид](https://github.com/SagerNet/sing-box-for-android)
- [Clash](https://github.com/Dreamacro/clash)
- [Clash Meta](https://github.com/MetaCubeX/Clash.Meta)
- [FClash](https://github.com/Fclash/Fclash)
- [Другие](./pubspec.yaml)

## Пожертвования и поддержка
Самый простой способ поддержать нас — нажать на звездочку (⭐) вверху этой страницы.

Нам также нужна финансовая поддержка для наших услуг. Вся наша деятельность осуществляется на добровольных началах, а финансовая поддержка будет направлена на развитие проекта. Вы можете просмотреть адреса нашей поддержки [здесь](https://github.com/hiddify/hiddify-server/wiki/support).

## Сотрудничество и контактная информация

Нам нужно ваше сотрудничество для развития этого проекта. Если вы являетесь специалистом в этих областях, пожалуйста, не стесняйтесь обращаться к нам.

- Flutter Разработка
- Swift Разработка
- Коtlin Разработка
- Go Разработка

<div align=center>

<br>

[![Email](https://img.shields.io/badge/Email-contribute@hiddify.com-005FF9?style=flat-square&logo=mail.ru)](mailto:contribute@hiddify.com)
[![Telegram Channel](https://img.shields.io/endpoint?label=Channel&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify&color=blue)](https://telegram.dog/hiddify)
[![Telegram Group](https://img.shields.io/endpoint?color=neon&label=Support%20Group&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify_board)](https://telegram.dog/hiddify_board)
[![Youtube](https://img.shields.io/youtube/channel/views/UCxrmeMvVryNfB4XL35lXQNg?label=Youtube&style=flat-square&logo=youtube)](https://www.youtube.com/@hiddify)
[![Twitter](https://img.shields.io/twitter/follow/hiddify_com?color=%231DA1F2&logo=twitter&logoColor=1DA1F2&style=flat-square)](https://twitter.com/intent/follow?screen_name=hiddify_com)

</div>
<p align=center>
Мы ценим всех людей, которые участвуют в этом проекте. Некоторые люди здесь и многие-многие другие за пределами Github. Это очень много значит для нас. ♥
 </p>
 
<p align=center> 
<a href="https://github.com/hiddify/hiddify-next/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=hiddify/hiddify-next" />
</a>
</p>
<p align=center>
 Сделано с <a rel="" target="_blank" href="https://contrib.rocks">Contrib.Rocks</a> 
</p>
