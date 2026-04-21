#!/usr/bin/env bash
#
# Generate the macOS AppIcon set from a single square source PNG
# (1024×1024 or larger). Run from anywhere — the target path is
# resolved relative to the repo root so it works regardless of the
# current working directory.
#
# Usage:
#   scripts/make-appicon.sh path/to/source.png
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SET="$REPO_ROOT/newsoftheworld/Assets.xcassets/AppIcon.appiconset"

SRC="${1:?usage: $0 <source-png-1024-or-larger>}"

if [[ ! -f "$SRC" ]]; then
  echo "Source not found: $SRC" >&2
  exit 1
fi
if [[ ! -d "$SET" ]]; then
  echo "AppIcon set not found: $SET" >&2
  echo "Expected to resolve relative to the repo root." >&2
  exit 1
fi

pairs=(
  "16    AppIcon-16.png"
  "32    AppIcon-16@2x.png"
  "32    AppIcon-32.png"
  "64    AppIcon-32@2x.png"
  "128   AppIcon-128.png"
  "256   AppIcon-128@2x.png"
  "256   AppIcon-256.png"
  "512   AppIcon-256@2x.png"
  "512   AppIcon-512.png"
  "1024  AppIcon-512@2x.png"
)

for pair in "${pairs[@]}"; do
  read -r size name <<< "$pair"
  sips -z "$size" "$size" "$SRC" --out "$SET/$name" >/dev/null
  printf "  %-22s %d×%d\n" "$name" "$size" "$size"
done

[[ -f "$SET/AppIcon-1024.png" ]] && rm "$SET/AppIcon-1024.png" \
  && echo "  removed legacy AppIcon-1024.png"

cat > "$SET/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "AppIcon-16.png",     "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "AppIcon-16@2x.png",  "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "AppIcon-32.png",     "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "AppIcon-32@2x.png",  "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "AppIcon-128.png",    "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "AppIcon-128@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "AppIcon-256.png",    "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "AppIcon-256@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "AppIcon-512.png",    "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "AppIcon-512@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON

echo "Done. Clean build in Xcode (⇧⌘K, dann ⌘R)."
echo "Falls macOS das alte Icon cached: killall Dock"
