$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
flutter --version
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Web: flutter run -d chrome"
Write-Host "Build Web: flutter build web --release --no-web-resources-cdn"
