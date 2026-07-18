param(
    [string]$JavaHome = "",
    [string]$AndroidHome = ""
)

$ErrorActionPreference = "Stop"
$Project = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Resolve-Path (Join-Path $Project "..\..\..")
$Gradle = Join-Path $Root "android\build\gradlew.bat"

if (!(Test-Path $Gradle)) {
    throw "Android build template missing. Run tools/build_android_debug.ps1 first."
}

if ([string]::IsNullOrWhiteSpace($JavaHome)) {
    $JavaHome = if ($env:JAVA_HOME) { $env:JAVA_HOME } else { Join-Path $Root ".tools\jdk-17" }
}
if ([string]::IsNullOrWhiteSpace($AndroidHome)) {
    $AndroidHome = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $Root ".tools\android-sdk" }
}
if (!(Test-Path (Join-Path $JavaHome "bin/java.exe"))) {
    throw "JDK 17 not found. Pass -JavaHome or set JAVA_HOME."
}
if (!(Test-Path (Join-Path $AndroidHome "platform-tools"))) {
    throw "Android SDK not found. Pass -AndroidHome or set ANDROID_HOME."
}

$env:JAVA_HOME = (Resolve-Path $JavaHome).Path
$env:ANDROID_HOME = (Resolve-Path $AndroidHome).Path
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME

& $Gradle --no-daemon --console=plain --project-dir $Project :plugin:assembleRelease
if ($LASTEXITCODE -ne 0) {
    throw "PopugVPocketFilePicker Gradle build failed with exit code $LASTEXITCODE"
}

$Aar = Join-Path $Project "plugin\build\outputs\aar\plugin-release.aar"
$Destination = Join-Path $Root "android\plugins\PopugVPocketFilePicker.aar"
Copy-Item -Force $Aar $Destination
Get-Item $Destination
