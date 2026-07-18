# Android Build

OpenPocket 0.4.0 targets portrait Android with package id `org.openpocket.app`, `versionName` 0.4.0, and `versionCode` 6.

## Requirements

- Godot 4.7 stable without .NET.
- Matching Godot 4.7 Android export templates.
- JDK 17.
- Android SDK platform-tools, platform 36, and build-tools 35.0.1.

The repository does not include Godot, JDK, Android SDK, export templates, or signing keys. Install them normally or keep optional portable copies under ignored `.tools/` paths.

## Compact Debug APK

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_android_debug.ps1 `
  -Godot path\to\Godot_v4.7-stable_win64_console.exe `
  -JavaHome path\to\jdk-17 `
  -AndroidHome path\to\android-sdk `
  -Preset "Android Compact Debug" `
  -Output exports\android\openpocket-0.4.0-compact-debug.apk
```

`-Godot` may be omitted when `godot` or `godot4` is on `PATH`. `-JavaHome` and `-AndroidHome` may be omitted when `JAVA_HOME` and `ANDROID_HOME` are set. The script installs the matching Godot Android build template into the ignored `android/build/` directory when needed.

The compact preset exports arm64, keeps the OpenPocket SAF plugin, and compresses the native Godot library. It is debug-signed for local testing.

## AAB

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_android_debug.ps1 `
  -Godot path\to\godot.exe `
  -JavaHome path\to\jdk-17 `
  -AndroidHome path\to\android-sdk `
  -Preset "Android Bundle" `
  -Output exports\android\openpocket-0.4.0.aab `
  -Release
```

The AAB preset is unsigned. Configure a production key outside the repository before distribution.

## Install On A Device

Enable USB debugging, connect the device, then use the SDK `adb` executable:

```powershell
adb devices
adb install -r exports\android\openpocket-0.4.0-compact-debug.apk
```

OpenPocket uses Android Storage Access Framework without broad storage permissions. INTERNET is enabled in 0.4.0 for HTTPS catalog and release asset GET requests.
