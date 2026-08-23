#!/usr/bin/env bash
set -e

echo "================================================="
echo "🚀 Starting Flutter Web Build on Vercel"
echo "================================================="

# Clone Flutter stable SDK if not cached
if [ ! -d "flutter" ]; then
  echo "📥 Cloning Flutter SDK (stable branch)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi

export PATH="$PATH:$PWD/flutter/bin"

echo "🔧 Checking Flutter Installation:"
flutter --version

echo "📦 Running flutter pub get..."
flutter pub get

echo "🏗️ Building Flutter Web (Release)..."
flutter build web --release --base-href /

# Ensure vercel.json is in build/web
cp vercel.json build/web/vercel.json || true

echo "================================================="
echo "✅ Flutter Web build complete! Output in build/web"
echo "================================================="
