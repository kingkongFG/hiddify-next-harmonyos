<div align="left" markdown="1" dir="ltr">

[**🇺🇸 English**](README.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[**🇨🇳 简体中文**](README_cn.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[**🇷🇺 Русский**](README_ru.md)

</div>

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

<div align="center">
   
   
[![GP-Intalls](https://img.shields.io/endpoint?color=green&logo=google-play&logoColor=green&url=https%3A%2F%2Fplay.cuzi.workers.dev%2Fplay%3Fi%3Dapp.hiddify.com%26l%3DGoogle%2520Play%26m%3D%24shortinstalls&style=flat-square)](https://play.google.com/store/apps/details?id=app.hiddify.com) [![Downloads](https://img.shields.io/github/downloads/hiddify/hiddify-next/total?style=flat-square&logo=github)](https://github.com/hiddify/hiddify-next/releases/)[![Last Version](https://img.shields.io/github/release/hiddify/hiddify-next/all.svg?style=flat-square)](https://github.com/hiddify/hiddify-next/)[![Last Release Date](https://img.shields.io/github/release-date/hiddify/hiddify-next.svg?style=flat-square)](https://github.com/hiddify/hiddify-next/)[![commits](https://img.shields.io/github/commit-activity/m/hiddify/hiddify-next?style=flat-square)](https://github.com/hiddify/hiddify-next/)
[![Youtube](https://img.shields.io/youtube/channel/views/UCxrmeMvVryNfB4XL35lXQNg?label=Youtube&style=flat-square&logo=youtube)](https://www.youtube.com/@hiddify)[![Telegram Channel](https://img.shields.io/endpoint?label=Channel&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify&color=blue)](https://telegram.dog/hiddify)[![Telegram Group](https://img.shields.io/endpoint?color=neon&label=Support%20Group&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify_board)](https://telegram.dog/hiddify_board)

</div>

## هیدیفای‌نکست چیست؟

یک کلاینت مالتی‌پلتفرم مبتنی بر [سینگ‌باکس](https://github.com/SagerNet/sing-box) که به عنوان یک ابزار عمومی برای پروکسی عمل می‌کند. این برنامه طیف گسترده‌ای از قابلیت‌ها را ارائه می‌دهد که در زیر لیست شده است. همچنین از تعداد زیادی پروتکل پشتیبانی می‌کند. این برنامه رایگان، بدون آگهی و منبع باز است. این یک ابزار امن و مطمئن برای دسترسی به اینترنت رایگان فراهم می‌کند.

این برنامه با استفاده از [Flutter](https://flutter.dev/) و [Go](https://go.dev/) توسعه یافته است. برای اطلاعات بیشتر در خصوص توسعه می‌توانید [دستورالعمل‌های مشارکت](https://github.com/hiddify/hiddify-next/blob/main/CONTRIBUTING.md) در پروژه ما را مطالعه نمایید.



<div align=center>
<img width=90% alt="Farsi Demo" src="https://github.com/hiddify/hiddify-next/assets/125398461/cfdc4b0e-0a26-42f5-90ef-1d8587d2afd2">

</div>



## 🚀 امکانات اصلی


⭐ استفاده بسیار آسان با رابط کاربری ساده

✈️ پشتیبانی از چند پلتفرم: اندروید، ویندوز، لینوکس و مک (پول رکوئست برای نسخه iOS استقبال می‌شود)

⚙️ بر پایه هسته سینگ‌باکس

🔍 انتخاب خودکار بهترین سرور و کانفیگ

🟡 پشتیبانی از رنج وسیعی از پروتکل‌ها
**ECH, Sing-box, V2ray, Xray, Vless, Vmess, Reality, TUIC, Hysteria, ShadowTLS, SSH, Clash, Clash meta**

🟡 پشتیبانی لینک‌های سابسکریپشن‌ مختلف:
**کلش، سینگ‌باکس و شدوساکس**

🔄 آپدیت خودکار لینک سابسکریپشن و کانفیگ‌ها

🔎 نمایش اطلاعات پروفایل کاربر شامل روز و حجم باقیمانده

💻 کاملا رایگان و بدون تبلیغات

🛡 اپن سورس و کاملا امن

🌙 دارای تم دارک و لایت

⚙ سازگار با تمام پنل‌ها

⭐ کانفیگ متناسب برای ایران، چین، روسیه و‌ سایر کشورها

📱 انتشار نسخه اندروید در [گوگل‌پلی](https://play.google.com/store/apps/details?id=app.hiddify.com)

## دانلود
<div dir=rtl align=right>

   <table>
    <thead align=center>
        <tr>
            <th>سیستم عامل</th>
            <th>دانلود</th>
        </tr>
    </thead>
    <tbody align=center>
        <tr>
        <td>اندروید</td><td>
            <a href="https://play.google.com/store/apps/details?id=app.hiddify.com"><img width=150px src="https://github.com/hiddify/hiddify-next/blob/main/docs/google-play-badge.png"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-universal.apk"><img src="https://img.shields.io/badge/APK-Universal-044d29.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-arm64.apk"><img src="https://img.shields.io/badge/APK-ArmV8-168039.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-arm7.apk"><img src="https://img.shields.io/badge/APK-ArmV7-45bf55.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-android-x86_64.apk"><img src="https://img.shields.io/badge/APK-x86_64-96ed89.svg?logo=github"></a>
        </td>
        </tr>
        <tr>
            <td>ویندوز</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-windows-x64-setup.zip"><img src="https://img.shields.io/badge/Setup-x64-0078d7.svg?logo=github"></a><br>
            <a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-windows-x64-portable.zip"><img src="https://img.shields.io/badge/Portable-x64-2d7d9a.svg?logo=github"></a>
        </td>
        </tr>
        <tr>
            <td>مک</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-macos-universal.zip"><img src="https://img.shields.io/badge/DMG-Universal-ea005e.svg?logo=github"></a></td>
        </tr>
        <tr>
            <td>لینوکس</td>
            <td><a href="https://github.com/hiddify/hiddify-next/releases/latest/download/hiddify-linux-x64.zip"><img src="https://img.shields.io/badge/AppImage-amd64-f84e29.svg?logo=github"> </a></td>
        </tr>
    </tbody>
</table>


## سپاسگزاری

- [سینگ‌باکس](https://github.com/SagerNet/sing-box)
- [سینگ‌باکس برای اندروید](https://github.com/SagerNet/sing-box-for-android)
- [کلش](https://github.com/Dreamacro/clash)
- [کلش‌متا](https://github.com/MetaCubeX/Clash.Meta)
- [اف‌کلش](https://github.com/Fclash/Fclash)
- [سایر](./pubspec.yaml)

## حمایت از پروژه

ساده‌ترین راه حمایت از ما کلیک کردن روی ستاره (⭐) بالای همین صفحه است.

ما برای سرویس هایمان به کمک مالی هم نیاز داریم. تمامی فعالیت‌های ما به صورت داوطلبانه انجام می‌شود و حمایت‌های مالی صرف توسعه پروژه می‌شود. اطلاعات و آدرس‌های حمایت‌ از ما را در [این لینک](https://github.com/hiddify/hiddify-server/wiki/support) مشاهده فرمایید.

## راه‌های همکاری و ارتباط با ما

اگر در هر یک از زمینه‌های زیر توانایی دارید، لطفا با ما در تماس باشید.

- برنامه‌نویسی فلاتر
- برنامه‌نویسی سوئیفت
- برنامه‌نویسی کاتلین
- برنامه‌نویسی Go

<br>
<div align=center>
    
[![Email](https://img.shields.io/badge/Email-contribute@hiddify.com-005FF9?style=flat-square&logo=mail.ru)](mailto:contribute@hiddify.com)
[![Telegram Channel](https://img.shields.io/endpoint?label=Channel&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify&color=blue)](https://telegram.dog/hiddify)
[![Telegram Group](https://img.shields.io/endpoint?color=neon&label=Support%20Group&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify_board)](https://telegram.dog/hiddify_board)
[![Youtube](https://img.shields.io/youtube/channel/views/UCxrmeMvVryNfB4XL35lXQNg?label=Youtube&style=flat-square&logo=youtube)](https://www.youtube.com/@hiddify)
[![Twitter](https://img.shields.io/twitter/follow/hiddify_com?color=%231DA1F2&logo=twitter&logoColor=1DA1F2&style=flat-square)](https://twitter.com/intent/follow?screen_name=hiddify_com)

 </div>
 
<p align=center>
 از همه کسانی که در این پروژه مشارکت می‌کنند سپاسگزاریم. بعضی از آن‌ها اینجا هستند و خیلی های دیگه خارج از گیتهاب. همگی خیلی برای ما ارزشمندند. ♥
 </p>
 
<p align=center> 
<a href="https://github.com/hiddify/hiddify-next/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=hiddify/hiddify-next" />
</a>
</p>
<p align=center>
 ساخته شده با <a rel="" target="_blank" href="https://contrib.rocks">Contrib.Rocks</a> 
</p>
