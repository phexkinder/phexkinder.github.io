#!/usr/bin/env bash
# Builds the new (old-WordPress-look) layout into new/, served at /new by GitHub Pages.
# Run from the repo root and commit the result:  ./build-new.sh && git add new
set -euo pipefail
cd "$(dirname "$0")"

rm -rf new
${JEKYLL:-bundle exec jekyll} build --config _config.yml,_config_new.yml

# Links inside post/page text are written as absolute paths (/mittelgruppe/...);
# keep them inside the preview. Shared assets (/assets/...) stay untouched.
find new -name '*.html' -print0 | xargs -0 sed -i -E \
  's#href="/(mittelgruppe|suedgruppe|impressum|20[0-9]{2}/)#href="/new/\1#g'
# Static search: index the finished pages (only elements marked data-pagefind-body are indexed).
# The version is pinned so the committed index stays reproducible. Needs Node.js.
PAGEFIND_VERSION=1.5.2
npx --yes "pagefind@${PAGEFIND_VERSION}" --site new --quiet

echo "Built new/ ($(find new -type f | wc -l) files)"
