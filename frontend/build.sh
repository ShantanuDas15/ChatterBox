#!/bin/bash
set -e

echo "========================================="
echo "ChatterBox Flutter Web Build Script"
echo "========================================="

# Install Flutter if not present
if [ ! -d "$HOME/flutter" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
else
  echo "Flutter already installed, updating..."
  cd $HOME/flutter
  git pull
  cd -
fi

# Add Flutter to PATH
export PATH="$HOME/flutter/bin:$PATH"
export PATH="$HOME/flutter/bin/cache/dart-sdk/bin:$PATH"

echo ""
echo "Flutter version:"
flutter --version

echo ""
echo "Enabling Flutter web..."
flutter config --enable-web

echo ""
echo "Running Flutter doctor..."
flutter doctor -v

echo ""
echo "Getting dependencies..."
flutter pub get

echo ""
echo "Building for web with environment variables..."
echo "API_BASE_URL: ${API_BASE_URL:-Not set}"
echo "GOOGLE_WEB_CLIENT_ID: ${GOOGLE_WEB_CLIENT_ID:0:20}..." # Show only first 20 chars

flutter build web --release \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID" \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --web-renderer canvaskit

echo ""
echo "========================================="
echo "Build complete!"
echo "Output directory: build/web"
echo "========================================="
