#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tooling/env.sh
sdk_path=/workspace/.toolchains/flutter
if [[ ! -x "$sdk_path/bin/flutter" ]]; then
  sdk_archive=$(mktemp /tmp/fan-flutter-XXXXXX.tar.xz)
  trap 'rm -f "$sdk_archive"' EXIT
  curl -fL --retry 2 https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.7-stable.tar.xz -o "$sdk_archive"
  printf '146df531f9ac6a11a918013c1a70faafc053d4811c8cb69a413fd70748d51c3d  %s\n' "$sdk_archive" | sha256sum -c -
  mkdir -p /workspace/.toolchains
  tar -xJf "$sdk_archive" -C /workspace/.toolchains
fi
flutter --version
python3 - <<'PY'
import json
from pathlib import Path
version = json.loads(Path('/workspace/.toolchains/flutter/bin/cache/flutter.version.json').read_text())['frameworkVersion']
if version != '3.35.7':
    raise SystemExit('Este setup usa Flutter 3.35.7. Preserve o SDK existente e ajuste a instalação separadamente.')
PY
flutter pub get --enforce-lockfile
npm ci --prefix firebase/tests --include=dev --no-audit --no-fund
