# Android Build

PopugVPocket 0.5.1 supports VBoy portrait and VGirl landscape Android profiles with package id `org.popugonet.popugvpocket`, `versionName` 0.5.1, and `versionCode` 7.

## Requirements

- Godot 4.7 stable without .NET.
- Matching Godot 4.7 Android export templates.
- JDK 17.
- Android SDK platform-tools, platforms 35 and 36, build-tools 35.0.1, CMake 3.10.2.4988404, and NDK 28.1.13356709.

The repository does not include Godot, JDK, Android SDK, export templates, or signing keys. Install them normally or keep optional portable copies under ignored `.tools/` paths. CI stores the SDK paths in an isolated Godot configuration through `tools/configure_ci_android.py` and generates a disposable standard Android debug keystore for each debug-prerelease run.

## Compact Debug APK

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_android_debug.ps1 `
  -Godot path\to\Godot_v4.7-stable_win64_console.exe `
  -JavaHome path\to\jdk-17 `
  -AndroidHome path\to\android-sdk `
  -Preset "Android Compact Debug" `
  -Output exports\android\popugvpocket-0.5.1-compact-debug.apk
```

`-Godot` may be omitted when `godot` or `godot4` is on `PATH`. `-JavaHome` and `-AndroidHome` may be omitted when `JAVA_HOME` and `ANDROID_HOME` are set. The script installs the matching Godot Android build template into the ignored `android/build/` directory when needed.

Every Android preset uses `branding/android/icon-legacy.png`, `icon-foreground.png`, and `icon-background.png`. The foreground is transparent and safe-zone padded; the background is full bleed. Keep the launcher fields synchronized when adding another Android preset.

The compact preset exports arm64, keeps the PopugVPocket SAF plugin, and compresses the native Godot library. It is debug-signed for local testing.

## AAB

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_android_debug.ps1 `
  -Godot path\to\godot.exe `
  -JavaHome path\to\jdk-17 `
  -AndroidHome path\to\android-sdk `
  -Preset "Android Bundle" `
  -Output exports\android\popugvpocket-0.5.1.aab `
  -Release
```

The local AAB preset is unsigned. Tagged releases currently default to `debug-prerelease`, publish only a debug-signed APK and checksum, and do not require repository secrets. `.github/workflows/release.yml` also keeps a manually selected `production` mode for later use with `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, and `ANDROID_KEY_ALIAS`; that mode additionally builds the AAB. Godot's Android export preset uses the same release password for the keystore entry. Production mode fails clearly when secrets are missing; keys are never committed.

## Install On A Device

Enable USB debugging, connect the device, then use the SDK `adb` executable:

```powershell
adb devices
adb install -r exports\android\popugvpocket-0.5.1-compact-debug.apk
```

PopugVPocket uses Android Storage Access Framework without broad storage permissions. INTERNET is enabled in 0.5.1 for HTTPS catalog and release asset GET requests. The runtime does not request `REQUEST_INSTALL_PACKAGES` and does not automatically install application APK updates.
