#!/bin/bash
set -e

echo "🚀 Starting Flutter Web Build for Vercel..."

# Check if Flutter SDK is installed; if not, clone the stable release
if [ ! -d "flutter" ]; then
  echo "📥 Cloning Flutter stable repository..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:`pwd`/flutter/bin"

echo "🔧 Flutter Version:"
flutter --version

echo "📦 Getting Flutter dependencies..."
flutter pub get

echo "🏗️ Building Flutter Web Release..."
flutter build web --release --base-href /

echo "✅ Flutter Web build finished successfully! Output located in build/web"
