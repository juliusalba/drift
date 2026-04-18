#!/usr/bin/env zsh
# Build + replace + relaunch DriftBar in one shot.
#
# Why this exists: xcodebuild defaults to DerivedData, the login item points
# at /Applications/DriftBar.app, and you may have launched the menu bar app
# from a third `build/` subdirectory. Three forks of the same binary is why
# "my change didn't take effect" keeps happening. This script collapses all
# three into one known-good copy and relaunches it.
#
# Usage:   ./dev-relaunch.sh
# Options: --no-install   don't copy into /Applications (dev-only)
#          --no-launch    build only, don't kill/relaunch

set -e
cd "$(dirname "$0")"

INSTALL=1
LAUNCH=1
for arg in "$@"; do
  case "$arg" in
    --no-install) INSTALL=0 ;;
    --no-launch)  LAUNCH=0  ;;
    *) echo "Unknown flag: $arg"; exit 2 ;;
  esac
done

BUILD_DIR="$PWD/build"
APP="$BUILD_DIR/Build/Products/Debug/DriftBar.app"

echo "▸ Building DriftBar (output → $BUILD_DIR)"
xcodebuild \
  -project DriftBar.xcodeproj \
  -scheme DriftBar \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$BUILD_DIR" \
  build \
  -quiet

if [[ ! -x "$APP/Contents/MacOS/DriftBar" ]]; then
  echo "✘ Build finished but no app at $APP"
  exit 1
fi

if (( LAUNCH )); then
  echo "▸ Killing any running DriftBar instances"
  pkill -f "DriftBar.app/Contents/MacOS/DriftBar" 2>/dev/null || true
  sleep 0.5
fi

if (( INSTALL )); then
  echo "▸ Syncing /Applications/DriftBar.app (so login item picks up fresh build)"
  rm -rf "/Applications/DriftBar.app"
  cp -R "$APP" "/Applications/DriftBar.app"
fi

if (( LAUNCH )); then
  TARGET="$APP"
  (( INSTALL )) && TARGET="/Applications/DriftBar.app"
  echo "▸ Launching $TARGET"
  open "$TARGET"
  sleep 0.5
  pid=$(pgrep -f "DriftBar.app/Contents/MacOS/DriftBar" | head -1)
  ts=$(stat -f "%Sm" "$TARGET/Contents/MacOS/DriftBar")
  echo "✓ DriftBar running (pid $pid, binary $ts)"
fi
