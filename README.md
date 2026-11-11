## About ReCore-Revamp

ReCore-Revamp is a maintained fork of [ReCoreUI](https://github.com/KrrishJaat/ReCoreUI), a OneUI port framework for Samsung phones. It patches supported Samsung firmware builds and generates a flashable ROM package with minimal manual intervention.

The upstream developer has ended support for ReCoreUI. This fork continues it with bug fixes for the Exynos 1330 phones listed below.

Current release: **ReCore-Revamp 8.5**

### Project Aim

To provide a modular, device-adaptive OneUI port framework that can patch supported Samsung firmware builds and generate a flashable ROM package with minimal manual intervention.

![Logo](readme/recore_banner.png)

---

## Supported devices

| Device | Model | Build objective | Status |
|---|---|---|---|
| Galaxy A14 5G | SM-A146B | `a14x` | Main development device |
| Galaxy A14 5G (Latin America) | SM-A146M | `a146m` | Untested |
| Galaxy M14 5G | SM-M146B | `m14x` | Untested |
| Galaxy F14 5G | SM-E146B | `f14x` | Untested |

"Untested" means the build is set up but has not been checked on a real phone by the maintainer. Expect bugs and report them.

---

## Fixes in this fork

- Fixed a black screen at the lowest brightness setting: the minimum backlight is no longer 0.
- Fixed the Samsung Camera crashing when switching to Video:
  - removed camera feature flags that this camera version cannot handle;
  - corrected the image codec entry to the version the camera app accepts, while keeping each device's own camera list.

## Known issues

- Bluetooth call audio (calls and microphone use over Bluetooth) may fail while music playback works.
- UPI and banking apps may refuse to run, because an unlocked bootloader cannot pass the stricter Play Integrity checks.
- Overall smoothness on devices with about 6 GB of RAM or less can be lower than stock.
- The kernel is a community build (see credits), not Samsung's stock kernel.

---

## ✨ Features

###  AI
- Selected AI features inspired by flagship Galaxy devices.

### Misc
- Selected flagship features 
- Battery health and charging cycles info
- Multiuser support enabled
- Dialogue booster AI in sound
- Fullscreen wallpaper on Always On Display
- Adaptive color tone
- Outdoor mode
- Custom font support 
- Official status in device information
- Modular debloat system
- Bluetooth library patched
- Samsung encryption removed
- Fixed Knox apps (Secure Folder,Secure WiFi,Private Share,Health etc)
- Fixed samsung wearables 
- Disabled secure screenshot detection
- Fixed SmartView
- Unlimited google photos storage with original quality 
- Enables some hidden device features
- And many more!

\* DeX via HDMI not available for devices without USB-C DP support

### CSC Features
- Network speed Meter
- AppLock support
- Data usage display on notification shade
- App blocker and permission manager
- AltZlife
- Native call recording
- And many more 

---

## Special Thanks

This project wouldn't be possible without the incredible work of:

- **[Salvo Giangreco](https://github.com/salvogiangri)** - The man behind the **[UN1CA](https://github.com/salvogiangri/UN1CA)** project and a true leader in the Samsung community. The initial ideas and inspiration that influenced early OneUI port development. 
- **[SameerAlSahab](https://github.com/SameerAlSahab)** - The initial ideas and inspiration behind the original framework of [AstroROM](https://github.com/SameerAlSahab/ProjectAstro).
- **[KrrishJaat](https://github.com/KrrishJaat)** - Creator of the original ReCoreUI, which this fork continues.
- **[BlassGO](https://github.com/BlassGO)** - For his Dynamic Installer.
- **[Danda420](https://github.com/Danda420)** - For his genfscontexts.
- **[jesec](https://github.com/jesec)** - For samfirm.js , which we use to download the latest firmwares.
- **[3arthur6](https://github.com/3arthur6)** - For bluetooth library patcher.
- **[soulr344](https://github.com/soulr344/OMCDecoder)** - For omc decoder.
- **[Pritam](https://github.com/nostalgiceagle)** - For fp patch and helping us to boot 8.5 on exynos 1330.
- **[Hunter](https://github.com/devhunter1)** - For Exynos 1330 [Kernel](https://github.com/devhunter1/android_kernel_samsung_s5e8535).
- **[Majaahh](https://github.com/majaahh)** - Gay Trans Polish Kid 
- **Thanks to Testers too**
---

## Licensing

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.
This project includes modifications based on the original framework by Sameer Al Sahab and the ReCoreUI project by KrrishJaat.

- **[android-tools](https://github.com/nmeum/android-tools)** - Licensed under Apache License 2.0
- **[apktool](https://github.com/iBotPeaches/Apktool)** - Licensed under Apache License 2.0  
- **[erofs-utils](https://github.com/sekaiacg/erofs-utils)** - Dual licensed (GPL-2.0, Apache-2.0)
- **[platform_build](https://android.googlesource.com/platform/build)** - Licensed under Apache License 2.0
- **[smali](https://github.com/google/smali)** - Licensed under BSD 3-Clause License
- **[e2fsprogs](https://github.com/tytso/e2fsprogs)** - Licensed under GPL-2.0 / LGPL-2.1
---

## Contributing

Contributors are welcome! Bug reports are most useful with a short description of the problem and the log from `adb logcat`.

---

## Disclaimer

This is an independent project and is not affiliated with or endorsed by Samsung Electronics or Google. All trademarks belong to their respective owners. Flashing a custom ROM can brick your phone and may void your warranty. You do this at your own risk.

---

<div align="center">

*If ReCore-Revamp helped you, consider supporting the project*

</div>
