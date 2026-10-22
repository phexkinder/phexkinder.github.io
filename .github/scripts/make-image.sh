#!/usr/bin/env bash
# Makes the web version of an image from its original: scaled down, metadata removed, progressive JPEG.
# Keep the full-resolution original in _originals/ (Jekyll does not publish folders starting with an
# underscore) and publish only the result in assets/img/. Needs ImageMagick.
#
#   .github/scripts/make-image.sh _originals/char-durin.jpg          # 900 px wide, written to assets/img/char-durin.jpg
#   .github/scripts/make-image.sh _originals/char-durin.jpg 1200     # another width
set -euo pipefail
cd "$(dirname "$0")/../.."

[ $# -ge 1 ] || { echo "usage: $0 _originals/<name>.jpg [width in px]" >&2; exit 2; }
src="$1"; width="${2:-900}"
[ -f "$src" ] || { echo "no such file: $src" >&2; exit 1; }
out="assets/img/$(basename "$src")"

convert "$src" -auto-orient -resize "${width}x>" -strip -interlace Plane -quality 82 "$out"
echo "$out: $(identify -format '%wx%h' "$out"), $(( $(wc -c < "$out") / 1024 )) KB"
