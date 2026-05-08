#!/bin/bash
set -euo pipefail

PRODUCT="BouncingDVD"
BUILD_DIR="build"
SAVER="$BUILD_DIR/$PRODUCT.saver"

rm -rf "$BUILD_DIR"
mkdir -p "$SAVER/Contents/MacOS"
mkdir -p "$SAVER/Contents/Resources"
cp Info.plist "$SAVER/Contents/"
cp DVD_logo.png "$SAVER/Contents/Resources/"

ARCH="$(uname -m)"
TARGET="${ARCH}-apple-macosx14.0"
SDK="$(xcrun --show-sdk-path)"
SWIFT_LIB="$(dirname $(xcrun --find swiftc))/../lib/swift/macosx"

swiftc \
    -parse-as-library \
    -c \
    -module-name "$PRODUCT" \
    -target "$TARGET" \
    -O \
    BouncingDVDView.swift \
    -o "$BUILD_DIR/BouncingDVDView.o"

clang \
    -target "$TARGET" \
    -bundle \
    -fobjc-arc \
    -isysroot "$SDK" \
    -framework ScreenSaver \
    -framework AppKit \
    -L "$SWIFT_LIB" \
    -lswiftCore \
    -Xlinker -rpath -Xlinker "$SWIFT_LIB" \
    "$BUILD_DIR/BouncingDVDView.o" \
    -o "$SAVER/Contents/MacOS/$PRODUCT"

codesign --force --sign - "$SAVER"

echo ""
echo "Built: $SAVER"
echo ""
echo "To install:"
echo "  sudo cp -R $SAVER /Library/Screen\\ Savers/"
echo ""
echo "Then open System Settings > Screen Saver and select 'Bouncing DVD'"
