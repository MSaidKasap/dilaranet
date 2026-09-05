#!/bin/sh

set -e

echo "Flutter indiriliyor..."

FLUTTER_VERSION="3.41.9"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_${FLUTTER_VERSION}-stable.zip"

curl -L -o flutter.zip "$FLUTTER_URL"

echo "Flutter açılıyor..."
unzip -q flutter.zip

export PATH="$PWD/flutter/bin:$PATH"

echo "Flutter version:"
flutter --version

echo "Pub get yapılıyor..."
cd $CI_PRIMARY_REPOSITORY_PATH
flutter pub get

echo "Pod install yapılıyor..."
cd ios
pod install --repo-update

echo "Tamamlandı!"