$ErrorActionPreference = "Stop"

$Script = Join-Path $PSScriptRoot "build_android_debug.ps1"

& $Script -Preset "Android Debug" -Output "exports/android/openpocket-0.3.2-development.apk"
& $Script -Preset "Android Compact Debug" -Output "exports/android/openpocket-0.3.2-compact-debug.apk"
& $Script -Preset "Android Bundle" -Output "exports/android/openpocket-0.3.2.aab" -Release
