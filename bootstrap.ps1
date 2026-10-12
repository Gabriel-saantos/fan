# Execute in PowerShell, from the FAN folder, with Flutter installed.
$ErrorActionPreference = "Stop"
Write-Host "Preparando projeto FAN para Android e Web..." -ForegroundColor Magenta
flutter create --platforms=android,web --project-name fan --org com.tooapps .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Para vincular Firebase: dart pub global activate flutterfire_cli; flutterfire configure --platforms=android,web" -ForegroundColor Cyan
Write-Host "Para testar: flutter run -d chrome | flutter run -d android" -ForegroundColor Green
