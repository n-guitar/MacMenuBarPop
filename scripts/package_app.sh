#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/MacMenuBarPop.app"
BIN_PATH="$ROOT_DIR/.build/release/MacMenuBarPop"
ICON_SRC="$ROOT_DIR/App/AppIcon.icns"

swift build -c release --package-path "$ROOT_DIR"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/MacMenuBarPop"
chmod +x "$APP_DIR/Contents/MacOS/MacMenuBarPop"
cp "$ROOT_DIR/App/Info.plist" "$APP_DIR/Contents/Info.plist"
if [[ -f "$ICON_SRC" ]]; then
  cp "$ICON_SRC" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

echo "Built: $APP_DIR"
