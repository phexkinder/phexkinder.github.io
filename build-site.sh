#!/usr/bin/env bash
# Builds the whole site into _site/: the main design at /, the old design (an archive) at /old/ and the font
# comparison copy at /font-test/, plus the search index of the main site. GitHub Actions publishes _site/ (see .github/workflows/deploy.yml).
# Needs Ruby/Bundler and Node.js. Run from anywhere:  ./build-site.sh
set -euo pipefail
cd "$(dirname "$0")"

rm -rf _site
${JEKYLL:-bundle exec jekyll} build --config _config.yml
${JEKYLL:-bundle exec jekyll} build --config _config.yml,_config_old.yml --destination _site/old
${JEKYLL:-bundle exec jekyll} build --config _config.yml,_config_font_test.yml --destination _site/font-test

# Links inside post/page text are written as absolute paths (/mittelgruppe/...);
# keep them inside the copies. Shared assets (/assets/...) stay untouched.
# "-i.bak" works with GNU sed (CI) and BSD sed (macOS); the backups are removed right after.
for copy in old font-test; do
  find "_site/$copy" -name '*.html' -print0 | xargs -0 sed -i.bak -E \
    "s#href=\"/(mittelgruppe|suedgruppe|impressum|20[0-9]{2}/)#href=\"/$copy/\\1#g"
  find "_site/$copy" -name '*.html.bak' -delete
done

# Static search: index the finished pages (only elements marked data-pagefind-body are indexed,
# which the old and font-test copies have none of). The version is pinned so builds stay reproducible.
PAGEFIND_VERSION=1.5.2
npx --yes "pagefind@${PAGEFIND_VERSION}" --site _site --quiet

echo "Built _site/ ($(find _site -type f | wc -l) files)"
