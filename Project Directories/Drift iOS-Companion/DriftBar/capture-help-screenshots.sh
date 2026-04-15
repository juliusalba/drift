#!/usr/bin/env bash
# Capture screenshots for the in-app Help manual.
# Usage: ./capture-help-screenshots.sh
# Prereqs: DriftBar is built and running. At least one drift run has completed
# (so the comparison view has real data).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$SCRIPT_DIR/DriftBar/Help/shots"
mkdir -p "$OUT"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1"; exit 2; }; }
need osascript
need screencapture

pgrep -x DriftBar >/dev/null || {
  echo "DriftBar is not running. Build+launch it first (Xcode: ⌘R), then re-run this script."
  exit 1
}

# Focus DriftBar
osascript -e 'tell application "DriftBar" to activate' 2>/dev/null || true
sleep 0.5

capture_window() {
  local title="$1" out="$2"
  # Find window by title and capture with window chrome
  local window_id
  window_id=$(osascript <<APPLESCRIPT 2>/dev/null || echo ""
tell application "System Events"
  tell process "DriftBar"
    set theWindow to first window whose title contains "$title"
    set {x, y} to position of theWindow
    set {w, h} to size of theWindow
    return (id of theWindow) as text
  end tell
end tell
APPLESCRIPT
  )
  if [[ -z "$window_id" ]]; then
    echo "  ! window '$title' not found — skipping"
    return 1
  fi
  screencapture -l"$window_id" -o -x "$out"
  echo "  ✓ $out"
}

echo "Capturing Help screenshots → $OUT"
echo ""

# 1. Menu bar popover
echo "[1/6] Menu bar popover — click the Drift icon in the menu bar, then press Enter."
read -r
screencapture -i -o "$OUT/02-menu.png"

# 2. Settings
echo "[2/6] Opening Settings…"
osascript -e 'tell application "System Events" to keystroke "," using command down' 2>/dev/null || true
sleep 1.0
capture_window "Settings" "$OUT/01-settings.png" || echo "  (manual capture fallback) click Settings window, press Enter." && read -r && screencapture -i -o "$OUT/01-settings.png"
capture_window "Settings" "$OUT/04-link-project.png" || true

# 3. Comparison view — needs the user to click a screen row
echo "[3/6] Click a screen row in the menu popover to open Comparison. Press Enter when visible."
read -r
capture_window "Comparison" "$OUT/03-comparison.png" || screencapture -i -o "$OUT/03-comparison.png"
cp "$OUT/03-comparison.png" "$OUT/06-diff.png" 2>/dev/null || true

# 4. Running state
echo "[4/6] Trigger a run (⌘R in the menu). When the bar icon glows yellow, press Enter."
read -r
screencapture -i -o "$OUT/05-running.png"

echo ""
echo "Done. Screenshots in $OUT"
ls -la "$OUT"
