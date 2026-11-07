#!/usr/bin/env bash
# Builds the whole site into _site/: the main design at / and the old design (an archive) at /old/,
# plus the search index of the main site. GitHub Actions publishes _site/ (see .github/workflows/deploy.yml).
# Needs Ruby/Bundler and Node.js. Run from anywhere:  ./build-site.sh
set -euo pipefail
cd "$(dirname "$0")"

rm -rf _site
${JEKYLL:-bundle exec jekyll} build --config _config.yml
${JEKYLL:-bundle exec jekyll} build --config _config.yml,_config_old.yml --destination _site/old

# Links inside post/page text are written as absolute paths (/mittelgruppe/...);
# keep them inside the old copy. Shared assets (/assets/...) stay untouched.
# "-i.bak" works with GNU sed (CI) and BSD sed (macOS); the backups are removed right after.
find _site/old -name '*.html' -print0 | xargs -0 sed -i.bak -E \
  's#href="/(mittelgruppe|suedgruppe|impressum|20[0-9]{2}/)#href="/old/\1#g'
find _site/old -name '*.html.bak' -delete

# Static search: index the finished pages (only elements marked data-pagefind-body are indexed,
# which the old copy has none of). The version is pinned so builds stay reproducible.
PAGEFIND_VERSION=1.5.2
npx --yes "pagefind@${PAGEFIND_VERSION}" --site _site --quiet

echo "Built _site/ ($(find _site -type f | wc -l) files)"
