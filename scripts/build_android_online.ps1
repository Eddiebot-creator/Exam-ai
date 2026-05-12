param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl
)

$ErrorActionPreference = "Stop"
$Flutter = "C:\flutter_windows_3.41.9-stable\flutter\bin\flutter.bat"
$JavaHome = "C:\Program Files\Android\Android Studio\jbr"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Frontend = Join-Path $ProjectRoot "frontend"

if (Test-Path $JavaHome) {
    $env:JAVA_HOME = $JavaHome
    $env:Path = "$env:JAVA_HOME\bin;$env:Path"
}

Push-Location $Frontend
try {
    & $Flutter build apk --release --dart-define=API_BASE_URL=$ApiBaseUrl
    & $Flutter build appbundle --release --dart-define=API_BASE_URL=$ApiBaseUrl
}
finally {
    Pop-Location
}

Write-Host "APK: $Frontend\build\app\outputs\flutter-apk\app-release.apk"
Write-Host "Play Store bundle: $Frontend\build\app\outputs\bundle\release\app-release.aab"
