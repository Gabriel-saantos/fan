#!/usr/bin/env bash
set -euo pipefail
printf '\nPreparando FAN para Android e Web...\n'
flutter create --platforms=android,web --project-name fan --org com.tooapps .
flutter pub get
printf '\nPara conectar Firebase: flutterfire configure --platforms=android,web\n'
printf 'Para testar: flutter run -d chrome\n'
