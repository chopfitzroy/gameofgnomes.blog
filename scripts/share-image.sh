#!/usr/bin/env bash
#
# Render a single share/OG card (1200x630 PNG) with ImageMagick.
#
# Layout: white canvas, the given title auto-fitted and centered as the bulk
# of the image, with a smaller bold "Game of Gnomes" site name at the bottom.
# The title caption has no fixed point size, so ImageMagick shrinks long
# titles to fit the box instead of clipping them.
#
# Fonts: static MonaSans-Bold.ttf, read directly from the repo `fonts/` dir
# (the source-of-truth TTFs, separate from the web-served woff2s in site/;
# the two are metrically identical, so this matches the on-site rendering).
#
# Usage: scripts/share-image.sh <title> <output.png>
set -euo pipefail

title="${1:?usage: share-image.sh <title> <output.png>}"
out="${2:?usage: share-image.sh <title> <output.png>}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
font="$repo_root/fonts/MonaSans-Bold.ttf"

magick -size 1200x630 xc:white \
  \( -background none -fill '#000000' -font "$font" \
     -interline-spacing -10 \
     -size 1080x460 -gravity Center caption:"$title" \) \
     -gravity North -geometry +0+50 -composite \
  \( -background none -fill '#000000' -font "$font" -pointsize 34 \
     -gravity South label:"Game of Gnomes" \) \
     -gravity South -geometry +0+48 -composite \
  -colorspace sRGB -type TrueColor "$out"
