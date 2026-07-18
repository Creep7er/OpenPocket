param(
    [string]$Output = "exports/android/openpocket-0.4.0-development.apk",
    [string]$Preset = "Android Debug",
    [string]$Godot = "",
    [string]$JavaHome = "",
    [string]$AndroidHome = "",
    [switch]$Release
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$AndroidBuild = Join-Path $Root "android/build"
$AndroidBuildVersion = Join-Path $Root "android/.build_version"
$PluginAar = Join-Path $Root "android/plugins/OpenPocketFilePicker.aar"

if ([string]::IsNullOrWhiteSpace($Godot)) {
    $PortableGodot = Join-Path $Root ".tools/godot/Godot_v4.7-stable_win64_console.exe"
    if (Test-Path $PortableGodot) {
        $Godot = $PortableGodot
    } else {
        $GodotCommand = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $GodotCommand) {
            $Godot = $GodotCommand.Source
        }
    }
}

if ([string]::IsNullOrWhiteSpace($Godot) -or !(Test-Path $Godot)) {
    throw "Godot 4.7 not found. Pass -Godot or add godot/godot4 to PATH."
}

if ([string]::IsNullOrWhiteSpace($JavaHome)) {
    $JavaHome = $env:JAVA_HOME
}
if ([string]::IsNullOrWhiteSpace($JavaHome)) {
    $PortableJdk = Join-Path $Root ".tools/jdk-17"
    if (Test-Path $PortableJdk) {
        $JavaHome = $PortableJdk
    }
}
if ([string]::IsNullOrWhiteSpace($JavaHome) -or !(Test-Path (Join-Path $JavaHome "bin/java.exe"))) {
    throw "JDK 17 not found. Pass -JavaHome or set JAVA_HOME."
}

if ([string]::IsNullOrWhiteSpace($AndroidHome)) {
    $AndroidHome = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $env:ANDROID_SDK_ROOT }
}
if ([string]::IsNullOrWhiteSpace($AndroidHome)) {
    $PortableSdk = Join-Path $Root ".tools/android-sdk"
    if (Test-Path $PortableSdk) {
        $AndroidHome = $PortableSdk
    }
}
if ([string]::IsNullOrWhiteSpace($AndroidHome) -or !(Test-Path (Join-Path $AndroidHome "platform-tools"))) {
    throw "Android SDK not found. Pass -AndroidHome or set ANDROID_HOME."
}

if (!(Test-Path (Join-Path $AndroidBuild "gradlew.bat"))) {
    Push-Location $Root
    try {
        & $Godot --headless --path . --install-android-build-template
        if ($LASTEXITCODE -ne 0) {
            throw "Godot could not install the Android build template. Install matching 4.7 export templates first."
        }
    } finally {
        Pop-Location
    }
}

if (!(Test-Path $AndroidBuildVersion)) {
    Set-Content -Encoding ASCII -Path $AndroidBuildVersion -Value "4.7.stable"
}

$BuildIgnore = Join-Path $AndroidBuild ".gdignore"
if (!(Test-Path $BuildIgnore)) {
    New-Item -ItemType File -Force -Path $BuildIgnore | Out-Null
}

$ResolvedBuild = (Resolve-Path $AndroidBuild).Path
foreach ($ImportSidecar in Get-ChildItem -Recurse -File -Filter "*.import" -LiteralPath $AndroidBuild) {
    $ResolvedSidecar = $ImportSidecar.FullName
    if (!$ResolvedSidecar.StartsWith($ResolvedBuild, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove import sidecar outside Android build directory: $ResolvedSidecar"
    }
    Remove-Item -Force -LiteralPath $ResolvedSidecar
}

if (!(Test-Path $PluginAar)) {
    & (Join-Path $Root "android/plugins/openpocket_file_picker/build_plugin.ps1") -JavaHome $JavaHome -AndroidHome $AndroidHome
    if ($LASTEXITCODE -ne 0) {
        throw "OpenPocketFilePicker build failed with exit code $LASTEXITCODE"
    }
}

$GeneratedAssets = Join-Path $AndroidBuild "src/main/assets"
if (Test-Path $GeneratedAssets) {
    $ResolvedAssets = (Resolve-Path $GeneratedAssets).Path
    if (!$ResolvedAssets.StartsWith($ResolvedBuild, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean generated assets outside Android build directory: $ResolvedAssets"
    }
    Remove-Item -Recurse -Force -LiteralPath $ResolvedAssets
}

$env:JAVA_HOME = (Resolve-Path $JavaHome).Path
$env:ANDROID_HOME = (Resolve-Path $AndroidHome).Path
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME

$OutputPath = Join-Path $Root $Output
$OutputDir = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Push-Location $Root
try {
    $ExportMode = if ($Release) { "--export-release" } else { "--export-debug" }
    & $Godot --headless --path . $ExportMode $Preset $Output
    if ($LASTEXITCODE -ne 0) {
        throw "Godot Android export failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

if (!(Test-Path $OutputPath)) {
    throw "APK was not created: $OutputPath"
}

$CompatiblePath = Join-Path $Root "exports/android/openpocket-debug.apk"
if ($Preset -eq "Android Debug" -and $OutputPath -ne $CompatiblePath) {
    Copy-Item -Force $OutputPath $CompatiblePath
}

Get-Item $OutputPath
