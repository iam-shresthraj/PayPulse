#!/bin/bash

# Exit on any error
set -e

echo "=== Starting Flutter Web Build ==="

# Configure git to avoid dubioust ownership errors in CI/CD (Vercel)
git config --global --add safe.directory "*" || true

# 1. Download Flutter SDK if not already present or if incomplete
if [ ! -d "flutter-sdk" ] || [ ! -f "flutter-sdk/bin/flutter" ]; then
  echo "Cloning clean Flutter SDK (stable branch)..."
  rm -rf flutter-sdk
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter-sdk
else
  echo "Using existing Flutter SDK..."
fi

# 2. Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter-sdk/bin"

# 3. Enable Web support and verify
flutter config --enable-web
flutter doctor || true

# 4. Build Flutter Web App
echo "Building Flutter Web Release version..."
cd swarnayan_flutter
flutter pub get
flutter build web --release


echo "=== Build Succeeded! ==="
