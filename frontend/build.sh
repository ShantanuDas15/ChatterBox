#!/bin/bash

# Use the FLUTTER_VERSION from Netlify's environment variables
# Fallback to a default if not set
VER=${FLUTTER_VERSION:-"3.24.5"}

echo "========================================="
echo "ChatterBox Flutter Web Build Script"
echo "Installing Flutter SDK v$VER..."
echo "========================================="

git clone https://github.com/flutter/flutter.git --depth 1 --branch $VER _flutter
export PATH="$PWD/_flutter/bin:$PATH"

flutter --version

echo "Enabling Flutter web..."
flutter config --enable-web

echo "Running Flutter doctor..."
flutter doctor

echo "Getting dependencies..."
flutter pub get

echo "Building Flutter web with environment variables..."
# Pass environment variables to the build
flutter build web --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID"

echo "Build complete."
