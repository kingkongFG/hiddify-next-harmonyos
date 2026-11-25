<div dir="ltr">
    
[**![Lang_farsi](https://user-images.githubusercontent.com/125398461/234186932-52f1fa82-52c6-417f-8b37-08fe9250a55f.png) فارسی**](README_fa.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[**Русский 🇷🇺**](README_ru.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[**简体中文 🇨🇳**](README_cn.md)

</div>

<p align="center"><img src="assets/images/logo.svg" width="168"/></p>

> ### ⚠️ Unofficial HarmonyOS (OpenHarmony) port — read this first
>
> This repository is a **fork of [Hiddify-Next](https://github.com/hiddify/hiddify-next) by the Hiddify team**, not an original product. The client design, the Dart/Flutter application code and UI, and the `sing-box` based core all come from the upstream project and its contributors. This repository **only maintains the HarmonyOS adaptation**; the official app lives upstream.
>
> What this fork actually changes:
>
> - **Added an ArkTS native host project** under `ohos/`: `EntryAbility`, `VpnExtAbility` (VPN extension ability), `VpnTunFactory` / `VpnTunStore` / `VpnRpc` (TUN device and fd passing), `VpnUiBridge` (Dart ↔ ArkTS channel), `OhosPlatformService` and plugin registration.
> - **The Dart layer is inherited from upstream and is *not* rewritten in ArkTS.** Only the platform/native layer is ArkTS.
> - The Go `sing-box` core is rebuilt for `openharmony/arm64` with the `lwip` network stack and shipped as `ohos/entry/libs/arm64-v8a/libcore.so`.
> - Supported platform: HarmonyOS phone / tablet (arm64, bundle name `com.hiddify.harmony`). HarmonyOS PC (x86_64) is **not** supported yet.
>
> License: this port inherits the upstream **CC BY-NC-SA 4.0** license. All original copyright remains with the upstream authors. Please report port-specific bugs in **this** repository, not upstream.

<div align="center">
    
[![GP-Intalls](https://img.shields.io/endpoint?color=green&logo=google-play&logoColor=green&url=https%3A%2F%2Fplay.cuzi.workers.dev%2Fplay%3Fi%3Dapp.hiddify.com%26l%3DGoogle%2520Play%26m%3D%24shortinstalls&style=flat-square)](https://play.google.com/store/apps/details?id=app.hiddify.com) [![Downloads](https://img.shields.io/github/downloads/hiddify/hiddify-next/total?style=flat-square&logo=github)](https://github.com/hiddify/hiddify-next/releases/)[![Last Version](https://img.shields.io/github/release/hiddify/hiddify-next/all.svg?style=flat-square)](https://github.com/hiddify/hiddify-next/)[![Last Release Date](https://img.shields.io/github/release-date/hiddify/hiddify-next.svg?style=flat-square)](https://github.com/hiddify/hiddify-next/)[![commits](https://img.shields.io/github/commit-activity/m/hiddify/hiddify-next?style=flat-square)](https://github.com/hiddify/hiddify-next/)
[![Youtube](https://img.shields.io/youtube/channel/views/UCxrmeMvVryNfB4XL35lXQNg?label=Youtube&style=flat-square&logo=youtube)](https://www.youtube.com/@hiddify)[![Telegram Channel](https://img.shields.io/endpoint?label=Channel&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify&color=blue)](https://telegram.dog/hiddify)[![Telegram Group](https://img.shields.io/endpoint?color=neon&label=Support%20Group&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify_board)](https://telegram.dog/hiddify_board/5)

</div>

## What is Hiddify-Next?

<p dir="ltr" style="font-size: 16px">A multi-platform client based on <a href="https://github.com/SagerNet/sing-box">Sing-box</a> that serves as a universal proxy toolchain. This app offers a wide range of capabilities, which are listed below. It also supports a large number of protocols. The app is free to use, ad-free, and open-source. It provides a secure and private tool for getting access to the free internet. </p>

The app is developed using [Flutter](https://flutter.dev) and [Go](https://go.dev). For more information you can read through our [Contribution Guidelines](https://github.com/hiddify/hiddify-next/blob/main/CONTRIBUTING.md) for development.

<p dir="ltr" style="font-size: 16px"><strong>Note for this repository:</strong> the description above is about the <strong>upstream</strong> Hiddify-Next project, not about work done here. In this fork the Flutter/Dart application and its dependencies are kept as-is, and <strong>HarmonyOS support is added through a new ArkTS native layer</strong> plus a re-compiled Go core for <code>openharmony/arm64</code>. Claiming that this client was "developed from scratch in ArkTS for HarmonyOS" is incorrect — see the notice at the top of this page for the exact scope of the changes.</p>

<div align=center>
<img width=90% alt="English Demo" src="https://github.com/hiddify/hiddify-next/assets/125398461/ffe5346d-3404-470f-b5e0-4364e23743d2">


</div>

## 🚀 Main features

⭐ Easy to use with a simple UI

✈️ Multi-platform: Android, Windows, Linux and macOS (PRs for iOS are welcome)

📱 **This fork targets HarmonyOS phone / tablet (arm64) only.** The platform list above and the download table below refer to upstream official builds — no prebuilt HarmonyOS package is published by this repository; build it locally with the OpenHarmony Flutter toolchain and DevEco Studio.

🔍 Auto selection based on delay

🟡 Wide range of protocols:
**ECH, Sing-box, V2ray, Xray, Vless, Vmess, Reality, TUIC, Hysteria, ShadowTLS, SSH, Clash, Clash meta**

🟡 Subscription links:
**Clash, Clash meta, Sing-box and Shadowsocks**

🔄 Automatic subscription update

🔎 Display profile information including remaining days and traffic usage

💻 Completely free and without any ads and interruptions

🛡 Open source and community driven

🌙 Dark and light modes

⚙ Compatible with all proxy management panels

⭐ Appropriate configuration for Iran, China, Russia and other countries

📱 Available on [Google Play](https://play.google.com/store/apps/details?id=app.hiddify.com)

## Download

<div align=left>
<table>
    <thead align=center>
        <tr>
            <th>OS</th>
            <th>Download</th>
        </tr>
    </thead>
    <tbody align=center>
        <tr>
        <td>Android</td><td>
            <a href="https://play.google.com/store/apps/details?id=app.hiddify.com"><img width=150px src="https://github.com/hiddify/hiddify-next/blob/main/docs/google-play-badge.png"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-universal.apk"><img src="https://img.shields.io/badge/APK-Universal-044d29.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-arm64.apk"><img src="https://img.shields.io/badge/APK-ArmV8-168039.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-arm7.apk"><img src="https://img.shields.io/badge/APK-ArmV7-45bf55.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-x86_64.apk"><img src="https://img.shields.io/badge/APK-x86_64-96ed89.svg?logo=github"></a>
        </td>
        </tr>
        <tr>
            <td>Windows</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-windows-x64-setup.zip"><img src="https://img.shields.io/badge/Setup-x64-0078d7.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-windows-x64-portable.zip"><img src="https://img.shields.io/badge/Portable-x64-2d7d9a.svg?logo=github"></a>
        </td>
        </tr>
        <tr>
            <td>macOS</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-macos-universal.zip"><img src="https://img.shields.io/badge/DMG-Universal-ea005e.svg?logo=github"></a></td>
        </tr>
        <tr>
            <td>Linux</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-linux-x64.zip"><img src="https://img.shields.io/badge/AppImage-amd64-f84e29.svg?logo=github"> </a></td>
        </tr>
    </tbody>
</table>


</div>

## Acknowledgements

- [Sing-box](https://github.com/SagerNet/sing-box)
- [Sing-box for Android](https://github.com/SagerNet/sing-box-for-android)
- [Clash](https://github.com/Dreamacro/clash)
- [Clash Meta](https://github.com/MetaCubeX/Clash.Meta)
- [FClash](https://github.com/Fclash/Fclash)
- [Others](./pubspec.yaml)

## Donation and Support

The easiest way to support us is to click on the star (⭐) at the top of this page.

We also need financial support for our services. All of our activities are done voluntarily and financial support will be spent on the development of the project. You can view our support addresses [here](https://github.com/hiddify/hiddify-server/wiki/support).

## Collaboration and Contact Information

We need your collaboration in order to develop this project. If you are specialists in these areas, please do not hesitate to contact us.

- Flutter Developing
- Swift Developing
- Kotlin Developing
- Go Developing
<div align=center>

<br>

[![Email](https://img.shields.io/badge/Email-contribute@hiddify.com-005FF9?style=flat-square&logo=mail.ru)](mailto:contribute@hiddify.com)
[![Telegram Channel](https://img.shields.io/endpoint?label=Channel&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify&color=blue)](https://telegram.dog/hiddify)
[![Telegram Group](https://img.shields.io/endpoint?color=neon&label=Support%20Group&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify_board)](https://telegram.dog/hiddify_board)
[![Youtube](https://img.shields.io/youtube/channel/views/UCxrmeMvVryNfB4XL35lXQNg?label=Youtube&style=flat-square&logo=youtube)](https://www.youtube.com/@hiddify)
[![Twitter](https://img.shields.io/twitter/follow/hiddify_com?color=%231DA1F2&logo=twitter&logoColor=1DA1F2&style=flat-square)](https://twitter.com/intent/follow?screen_name=hiddify_com)

</div>

<p align=center>
 We appreciate all people who are participating in this project. Some people here and many many more outside of Github. It means a lot to us. ♥
 </p>
 
<p align=center> 
<a href="https://github.com/hiddify/hiddify-next/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=hiddify/hiddify-next" />
</a>
</p>
<p align=center>
 Made with <a rel="" target="_blank" href="https://contrib.rocks">Contrib.Rocks</a> 
</p>
