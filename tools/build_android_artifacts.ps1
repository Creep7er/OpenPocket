$ErrorActionPreference = "Stop"

$Script = Join-Path $PSScriptRoot "build_android_debug.ps1"

& $Script -Preset "Android Debug" -Output "exports/android/popugvpocket-0.5.1-development.apk"
& $Script -Preset "Android Compact Debug" -Output "exports/android/popugvpocket-0.5.1-compact-debug.apk"
& $Script -Preset "Android Bundle" -Output "exports/android/popugvpocket-0.5.1.aab" -Release
