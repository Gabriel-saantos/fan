#!/usr/bin/env bash
# Source this file inside the Codex cloud environment.
export XDG_CONFIG_HOME=/workspace/.tooling-config
export XDG_CACHE_HOME=/workspace/.tooling-cache
export PUB_CACHE=/workspace/.pub-cache
export ANALYZER_STATE_LOCATION_OVERRIDE=/workspace/.dart-server
export FIREBASE_EMULATORS_PATH=/workspace/.firebase-emulators
export npm_config_cache=/workspace/.npm-cache
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
export PATH="/workspace/.toolchains/flutter/bin:$PATH"
