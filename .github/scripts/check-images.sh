#!/usr/bin/env bash
# Fails if an image in assets/img/ is larger than 500 KB, so a camera original or an unscaled scan cannot
# slip into the site (every visitor would download it). Shrink it first, e.g. with ImageMagick:
#   convert original.jpg -auto-orient -resize 900x -strip -interlace Plane -quality 82 assets/img/name.jpg
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

limit_kb=500
big=$(git ls-files -z 'assets/img/*' | xargs -0 -r du -k | awk -v max="$limit_kb" '$1 > max {print $2 " (" $1 " KB)"}')
if [ -n "$big" ]; then
  echo "::error::Images larger than ${limit_kb} KB, please scale them down (see the comment in .github/scripts/check-images.sh):"
  echo "$big"
  exit 1
fi
echo "All images are at most ${limit_kb} KB."
