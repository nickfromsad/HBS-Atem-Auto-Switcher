#!/bin/bash
# Builds "HBS ATEM Auto Switcher.app" and an HBS-styled .dmg in dist/ (macOS only).
#
# Needs Python 3.11+ with:  pip install pyinstaller PyQt6 sounddevice numpy
# plus uv (for dmgbuild) and the Xcode Command Line Tools (swift, iconutil).
# Locally, without installing anything globally:
#   uv run --python 3.12 --with pyinstaller --with PyQt6 --with sounddevice --with numpy packaging/macos/build-mac.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
ROOT="$PWD"

APP_NAME="HBS ATEM Auto Switcher"
BUNDLE_ID="nl.hofbroadcast.AtemAutoSwitcher"
VERSION=$(python3 -c "import re; print(re.search(r'APP_VERSION = \"([^\"]+)\"', open('atem_switcher.pyw', encoding='utf-8').read()).group(1))")
WORK="$ROOT/build/macos"
APP="$ROOT/dist/$APP_NAME.app"
DMG="$ROOT/dist/HBS-ATEM-Auto-Switcher-$VERSION.dmg"

rm -rf "$WORK" "$APP" "$DMG"
mkdir -p "$WORK"

echo "▸ Icon (from the icon embedded in atem_switcher.pyw)"
python3 - "$WORK/logo-256.png" <<'EOF'
import base64, re, struct, sys
src = open("atem_switcher.pyw", encoding="utf-8").read()
ico = base64.b64decode(re.search(r'_ICON_B64 = "([^"]+)"', src).group(1))
count = struct.unpack("<H", ico[4:6])[0]
entries = [struct.unpack("<BBBBHHII", ico[6 + 16 * i:22 + 16 * i]) for i in range(count)]
w, h, *_, size, offset = max(entries, key=lambda e: e[0] or 256)   # 0 means 256 px
open(sys.argv[1], "wb").write(ico[offset:offset + size])
EOF
swift packaging/macos/make-icon.swift "$WORK/logo-256.png" "$WORK/AppIcon.iconset"
iconutil -c icns "$WORK/AppIcon.iconset" -o "$WORK/AppIcon.icns"

echo "▸ App $VERSION"
pyinstaller --noconfirm --log-level WARN --windowed \
    --name "$APP_NAME" --icon "$WORK/AppIcon.icns" --osx-bundle-identifier "$BUNDLE_ID" \
    --distpath "$ROOT/dist" --workpath "$WORK/pyinstaller" --specpath "$WORK" \
    "$ROOT/atem_switcher.pyw"

PLIST="$APP/Contents/Info.plist"
plist() {   # plist <key> <type> <value>: set, or add when missing
    /usr/libexec/PlistBuddy -c "Set :$1 $3" "$PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$PLIST"
}
plist CFBundleDisplayName string "$APP_NAME"
plist CFBundleShortVersionString string "$VERSION"
plist CFBundleVersion string "$VERSION"
plist LSMinimumSystemVersion string "12.0"
plist NSHighResolutionCapable bool true
plist NSHumanReadableCopyright string "HBS // Hof Broadcast Services · MIT License"
# Without these macOS silently feeds zeros instead of audio, and blocks the ATEM connection.
plist NSMicrophoneUsageDescription string "HBS ATEM Auto Switcher listens to the audio levels of your microphones (e.g. Dante Virtual Soundcard) to decide which camera goes on air."
plist NSLocalNetworkUsageDescription string "HBS ATEM Auto Switcher connects to your ATEM switcher and lets Bitfocus Companion control it over the local network."

# Editing Info.plist invalidates PyInstaller's ad-hoc signature, so sign again.
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

echo "▸ Disk image"
swift packaging/macos/make-dmg-background.swift "$VERSION" "$WORK/dmg"
tiffutil -cathidpicheck "$WORK/dmg/background.png" "$WORK/dmg/background@2x.png" -out "$WORK/dmg/background.tiff"
uvx --quiet --from dmgbuild==1.6.7 dmgbuild -s packaging/macos/dmg-settings.py \
    -D app="$APP" -D background="$WORK/dmg/background.tiff" -D icon="$WORK/AppIcon.icns" \
    "$APP_NAME" "$DMG"

echo "✓ $APP"
echo "✓ $DMG"
