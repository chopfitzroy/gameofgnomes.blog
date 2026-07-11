#!/usr/bin/env bash
#
# Generate per-post share/OG images and place them in the build output.
#
# Must run AFTER `soupault`, because it consumes the `index.json` that soupault
# dumps and writes PNGs into the already-generated `build/` tree.
#
# The Rust tool (scripts/share-images) is built in release mode on demand; the
# compiled binary is cached by cargo between runs, so repeat builds are fast.
#
# Usage: scripts/build-share-images.sh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

index_json="index.json"
fonts_dir="site/assets/fonts"
output_dir="build/og"

if [ ! -f "$index_json" ]; then
  echo "build-share-images: $index_json not found; run soupault first" >&2
  exit 1
fi

# Prefer a rustup-managed toolchain if present (takumi needs rustc >= 1.91),
# otherwise fall back to whatever `cargo` is on PATH.
if command -v rustup >/dev/null 2>&1; then
  cargo_cmd="rustup run stable cargo"
else
  cargo_cmd="cargo"
fi

echo "build-share-images: compiling tool (release)..."
$cargo_cmd build --release --manifest-path scripts/share-images/Cargo.toml

bin="scripts/share-images/target/release/share-images"
echo "build-share-images: rendering cards..."
"$bin" "$index_json" "$fonts_dir" "$output_dir"
