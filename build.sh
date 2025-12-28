#!/bin/bash

set -e

echo "Building MinimalAppUninstaller..."

# Build Release version
xcodebuild -project MinimalAppUninstaller.xcodeproj \
    -scheme MinimalAppUninstaller \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    clean build

# Create dist directory
mkdir -p dist

# Copy app to dist
cp -r build/DerivedData/Build/Products/Release/MinimalAppUninstaller.app dist/

echo ""
echo "Build complete!"
echo "App location: dist/MinimalAppUninstaller.app"
