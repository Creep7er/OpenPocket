param(
    [string]$Apk = "exports/android/openpocket-0.3.2-compact-debug.apk",
    [string]$Adb = ""
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$ApkPath = Join-Path $Root $Apk

if ([string]::IsNullOrWhiteSpace($Adb)) {
    $AndroidHome = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $env:ANDROID_SDK_ROOT }
    if ($AndroidHome) {
        $Adb = Join-Path $AndroidHome "platform-tools/adb.exe"
    }
}
if ([string]::IsNullOrWhiteSpace($Adb) -or !(Test-Path $Adb)) {
    $PortableAdb = Join-Path $Root ".tools/android-sdk/platform-tools/adb.exe"
    if (Test-Path $PortableAdb) {
        $Adb = $PortableAdb
    } else {
        $AdbCommand = Get-Command adb -ErrorAction SilentlyContinue
        if ($null -ne $AdbCommand) {
            $Adb = $AdbCommand.Source
        }
    }
}
if ([string]::IsNullOrWhiteSpace($Adb) -or !(Test-Path $Adb)) {
    throw "ADB not found. Pass -Adb, set ANDROID_HOME, or add adb to PATH."
}

if (!(Test-Path $ApkPath)) {
    & (Join-Path $PSScriptRoot "build_android_debug.ps1") -Output $Apk
}

$Devices = & $Adb devices
$Devices

$Connected = $Devices | Where-Object { $_ -match "\tdevice$" }
if (!$Connected) {
    throw "No authorized Android device found. Enable USB debugging, connect the phone, and accept the debugging prompt."
}

& $Adb install -r $ApkPath
