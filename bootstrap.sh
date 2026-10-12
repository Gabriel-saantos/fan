#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v flutter >/dev/null || { echo 'Instale Flutter 3.35+ e adicione flutter/bin ao PATH.' >&2; exit 1; }
flutter --version
flutter pub get
flutter analyze
flutter test
printf '\nWeb: flutter run -d chrome\nBuild Web: flutter build web --release --no-web-resources-cdn\n'
