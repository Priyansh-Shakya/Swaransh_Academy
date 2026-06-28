
# use command given below to run script
#? COMMAND: & "C:\Program Files\Git\bin\bash.exe" scripts/install_dependencies.sh


#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT" || exit 1

echo "Running from:"
pwd

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: pubspec.yaml not found"
  exit 1
fi

echo "Installing dependencies..."

dart pub add \
  flutter_riverpod \
  dio \
  go_router \
  flutter_dotenv \
  freezed_annotation \
  json_annotation \
  flutter_launcher_icons \
  flutter_dotenv

dart pub add \
  dev:build_runner \
  dev:freezed \
  dev:json_serializable \
  dev:riverpod_generator

echo "Done."