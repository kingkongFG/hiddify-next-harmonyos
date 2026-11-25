[**🇺🇸 English**](README.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[**🇷🇺 Русский**](README_ru.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[**![Lang_farsi](https://user-images.githubusercontent.com/125398461/234186932-52f1fa82-52c6-417f-8b37-08fe9250a55f.png) فارسی**](README_fa.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;


<p align="center"><img src="assets/images/logo.svg" width="168"/></p>

> ### ⚠️ 本仓库是 Hiddify-Next 的鸿蒙（OpenHarmony）非官方移植分支，请先阅读
>
> 本仓库是 **[Hiddify-Next](https://github.com/hiddify/hiddify-next)（Hiddify 团队）的 fork**，不是原创项目。客户端的产品设计、Dart/Flutter 应用代码与界面、以及基于 `sing-box` 的内核均来自上游项目及其贡献者。**本仓库只维护鸿蒙适配部分**，官方版本请前往上游仓库获取。
>
> 本分支实际改动的内容：
>
> - **新增 ArkTS 原生宿主工程** `ohos/`：`EntryAbility`、`VpnExtAbility`（VPN 扩展 Ability）、`VpnTunFactory` / `VpnTunStore` / `VpnRpc`（TUN 设备与 fd 传递）、`VpnUiBridge`（Dart ↔ ArkTS 通道）、`OhosPlatformService` 与插件注册。
> - **Dart 层沿用上游代码，并未改写为 ArkTS**；ArkTS 只覆盖平台/原生层。
> - Go `sing-box` 内核以 `openharmony/arm64` 目标、`lwip` 网络栈重新编译，产出 `ohos/entry/libs/arm64-v8a/libcore.so`。
> - 支持平台：鸿蒙手机 / 平板（arm64，包名 `com.hiddify.harmony`）；鸿蒙 PC（x86_64）**暂未支持**。
>
> 许可证：本移植分支继承上游 **CC BY-NC-SA 4.0** 许可证，原始著作权归上游作者所有。移植相关问题请反馈到**本仓库**，不要提交到上游。

<div align="center">
    
[![GP-Intalls](https://img.shields.io/endpoint?color=green&logo=google-play&logoColor=green&url=https%3A%2F%2Fplay.cuzi.workers.dev%2Fplay%3Fi%3Dapp.hiddify.com%26l%3DGoogle%2520Play%26m%3D%24shortinstalls&style=flat-square)](https://play.google.com/store/apps/details?id=app.hiddify.com) [![Downloads](https://img.shields.io/github/downloads/hiddify/hiddify-next/total?style=flat-square&logo=github)](https://github.com/hiddify/hiddify-next/releases/)[![Last Version](https://img.shields.io/github/release/hiddify/hiddify-next/all.svg?style=flat-square)](https://github.com/hiddify/hiddify-next/)[![Last Release Date](https://img.shields.io/github/release-date/hiddify/hiddify-next.svg?style=flat-square)](https://github.com/hiddify/hiddify-next/)[![commits](https://img.shields.io/github/commit-activity/m/hiddify/hiddify-next?style=flat-square)](https://github.com/hiddify/hiddify-next/)
[![Youtube](https://img.shields.io/youtube/channel/views/UCxrmeMvVryNfB4XL35lXQNg?label=Youtube&style=flat-square&logo=youtube)](https://www.youtube.com/@hiddify)[![Telegram Channel](https://img.shields.io/endpoint?label=Channel&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify&color=blue)](https://telegram.dog/hiddify)[![Telegram Group](https://img.shields.io/endpoint?color=neon&label=Support%20Group&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify_board)](https://telegram.dog/hiddify_board/5)

</div>


## 什么是 Hiddify-Next？
基于 [Sing-box](https://github.com/SagerNet/sing-box) 的多平台客户端，用作通用代理工具链。 该应用程序提供了广泛的功能，如下所列。 它还支持大量协议。 该应用程序免费使用、无广告且开源。 它提供了一个安全且私密的工具来访问免费互联网。

该应用程序是使用 [Flutter](https://flutter.dev/) 和 [Go](https://go.dev/) 开发的。 欲了解更多信息，您可以阅读我们的开发贡献指南。

**本仓库说明：** 以上介绍描述的是**上游** Hiddify-Next 项目，不代表本仓库的工作内容。本分支中 Flutter/Dart 应用及其依赖保持上游原样，**鸿蒙支持是通过新增 ArkTS 原生层 + 为 `openharmony/arm64` 重新编译 Go 内核实现的**。若表述为「本客户端为鸿蒙原生、用 ArkTS 从零开发」，属于错误描述，实际改动范围见本页顶部声明。


<div align=center>
<img width=90% alt="English Demo" src="https://github.com/hiddify/hiddify-next/assets/125398461/531d6db2-ae7a-4234-addd-1a32b76050b8">

</div>

## 🚀 主要特点
⭐ 简单的用户界面易于使用

✈️ 多平台：Android、Windows、Linux 和 macOS（欢迎 iOS 的 PR）

📱 **本分支仅面向鸿蒙手机 / 平板（arm64）。** 上述平台列表与下方下载表格均指上游官方构建，本仓库不发布鸿蒙预编译包，需用 OpenHarmony Flutter 工具链配合 DevEco Studio 本地构建。

🔍 基于延迟的自动选择

🟡 广泛的协议：ECH、Sing-box、V2ray、Xray、Vless、Vmess、Reality、TUIC、Hysteria、ShadowTLS、SSH、Clash、Clash meta

🟡 订阅链接：Clash、Clash meta、Sing-box 和 Shadowsocks

🔄 自动订阅更新

🔎 显示个人资料信息，包括剩余天数和流量使用情况

💻 完全免费，没有任何广告和干扰

🛡 开源和社区驱动

🌙 深色和浅色模式

⚙ 与所有代理管理面板兼容

⭐ 适合伊朗、中国、俄罗斯等国家配置

📱 可在 Google Play 上获取

## 下载

<div align=left>
<table>
    <thead align=center>
        <tr>
            <th>操作系统</th>
            <th>下载</th>
        </tr>
    </thead>
    <tbody align=center>
        <tr>
        <td>安卓</td><td>
            <a href="https://play.google.com/store/apps/details?id=app.hiddify.com"><img width=150px src="https://github.com/hiddify/hiddify-next/blob/main/docs/google-play-badge.png"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-universal.apk"><img src="https://img.shields.io/badge/APK-Universal-044d29.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-arm64.apk"><img src="https://img.shields.io/badge/APK-ArmV8-168039.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-arm7.apk"><img src="https://img.shields.io/badge/APK-ArmV7-45bf55.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-x86_64.apk"><img src="https://img.shields.io/badge/APK-x86_64-96ed89.svg?logo=github"></a>
        </td>
        </tr>
        <tr>
            <td>视窗</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-windows-x64-setup.zip"><img src="https://img.shields.io/badge/Setup-x64-0078d7.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-windows-x64-portable.zip"><img src="https://img.shields.io/badge/Portable-x64-2d7d9a.svg?logo=github"></a>
        </td>
        </tr>
        <tr>
            <td>苹果系统</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-macos-universal.zip"><img src="https://img.shields.io/badge/DMG-Universal-ea005e.svg?logo=github"></a></td>
        </tr>
        <tr>
            <td>Linux</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-linux-x64.zip"><img src="https://img.shields.io/badge/AppImage-amd64-f84e29.svg?logo=github"> </a></td>
        </tr>
    </tbody>
</table>

</div>

## 致谢
- [Sing-box](https://github.com/SagerNet/sing-box)
- [Sing-box 适用于安卓](https://github.com/SagerNet/sing-box-for-android)
- [Clash](https://github.com/Dreamacro/clash)
- [Clash Meta](https://github.com/MetaCubeX/Clash.Meta)
- [FClash](https://github.com/Fclash/Fclash)
- [其他的](./pubspec.yaml)
## 捐赠与支持

支持我们的最简单方法是点击本页顶部的星号 (⭐)。

我们的服务还需要财政支持。 我们所有的活动都是自愿进行的，财政支持将用于项目的开发。 您可以[此处](https://github.com/hiddify/hiddify-server/wiki/support)查看我们的支持地址

<div align=center>

<br>

[![Email](https://img.shields.io/badge/Email-contribute@hiddify.com-005FF9?style=flat-square&logo=mail.ru)](mailto:contribute@hiddify.com)
[![Telegram Channel](https://img.shields.io/endpoint?label=Channel&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify&color=blue)](https://telegram.dog/hiddify)
[![Telegram Group](https://img.shields.io/endpoint?color=neon&label=Support%20Group&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify_board)](https://telegram.dog/hiddify_board)
[![Youtube](https://img.shields.io/youtube/channel/views/UCxrmeMvVryNfB4XL35lXQNg?label=Youtube&style=flat-square&logo=youtube)](https://www.youtube.com/@hiddify)
[![Twitter](https://img.shields.io/twitter/follow/hiddify_com?color=%231DA1F2&logo=twitter&logoColor=1DA1F2&style=flat-square)](https://twitter.com/intent/follow?screen_name=hiddify_com)

</div>

<p align=center>
 我们感谢所有参与该项目的人。 这里有一些人，还有 Github 之外的更多人。 这对我们来说意义重大。 ♥
 </p>
 
<p align=center> 
<a href="https://github.com/hiddify/hiddify-next/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=hiddify/hiddify-next" />
</a>
</p>
<p align=center>
 制作与 <a rel="" target="_blank" href="https://contrib.rocks">Contrib.Rocks</a> 
</p>


