#!/bin/bash

# SaveSpace DMG Build Script
# Usage: ./scripts/build-dmg.sh

# Configuration
APP_NAME="SaveSpace"
SCHEME="SaveSpace"
PROJECT="SaveSpace.xcodeproj"
BUILD_DIR="build"
DMG_DIR="$BUILD_DIR/dmg"
RELEASE_DIR="$BUILD_DIR/Release"
VERSION=$(date +"%Y.%m.%d")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔨 Building $APP_NAME for Release...${NC}"

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"
mkdir -p "$DMG_DIR"

# Build the app
xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    clean build \
    CONFIGURATION_BUILD_DIR="$RELEASE_DIR" \
    2>&1 | tee "$BUILD_DIR/build.log"

# Check if app was built (ignore xcodebuild exit code, check for actual app)
if [ ! -d "$RELEASE_DIR/$APP_NAME.app" ]; then
    echo -e "${RED}❌ Build failed: $APP_NAME.app not found${NC}"
    echo "Check $BUILD_DIR/build.log for details"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"

# Create DMG
echo -e "${YELLOW}📦 Creating DMG...${NC}"

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
DMG_TEMP="$BUILD_DIR/temp.dmg"

# Prepare DMG contents
cp -R "$RELEASE_DIR/$APP_NAME.app" "$DMG_DIR/"

# Create symbolic link to Applications
ln -sf /Applications "$DMG_DIR/Applications"

# Create temporary DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDRW \
    "$DMG_TEMP"

# Convert to compressed DMG
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH"

# Clean up
rm -f "$DMG_TEMP"
rm -rf "$DMG_DIR"

# Get DMG size
DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)

echo -e "${GREEN}✅ DMG created successfully!${NC}"
echo -e "   📍 Location: ${YELLOW}$DMG_PATH${NC}"
echo -e "   📏 Size: ${YELLOW}$DMG_SIZE${NC}"

# Optional: Open the folder containing the DMG
# open "$BUILD_DIR"
