#!/usr/bin/env bash
#
# Render a single share/OG card (1200x630 PNG) with ImageMagick.
#
# Layout: white canvas, bold "Game of Gnomes" header centered at the top, a
# 2px black rule beneath it, and the given title auto-fitted and centered in
# the space below. The title caption has no fixed point size, so ImageMagick
# shrinks long titles to fit the box instead of clipping them.
#
# Fonts: static MonaSans-Bold.ttf, read directly from the repo `fonts/` dir
# (the source-of-truth TTFs, separate from the web-served woff2s in site/).
#
# Usage: scripts/share-image.sh <title> <output.png>
set -euo pipefail

title="${1:?usage: share-image.sh <title> <output.png>}"
out="${2:?usage: share-image.sh <title> <output.png>}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
font="$repo_root/fonts/MonaSans-Bold.ttf"

magick -size 1200x630 xc:white \
  \( -background none -fill '#000000' -font "$font" -pointsize 48 \
     -gravity North label:"Game of Gnomes" \) \
     -gravity North -geometry +0+64 -composite \
  -fill '#000000' -draw 'rectangle 64,150 1136,152' \
  \( -background none -fill '#000000' -font "$font" \
     -size 1000x380 -gravity Center caption:"$title" \) \
     -gravity North -geometry +0+195 -composite \
  -colorspace sRGB -type TrueColor "$out"
