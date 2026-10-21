#!/usr/bin/env bash
# Builds the whole site into _site/: the current design at / and the /new preview (old WordPress look)
# at /new/, plus the search index of /new. GitHub Actions publishes _site/ (see .github/workflows/deploy.yml).
# Needs Ruby/Bundler and Node.js. Run from anywhere:  ./build-site.sh
set -euo pipefail
cd "$(dirname "$0")"

rm -rf _site
${JEKYLL:-bundle exec jekyll} build --config _config.yml
${JEKYLL:-bundle exec jekyll} build --config _config.yml,_config_new.yml --destination _site/new

# Links inside post/page text are written as absolute paths (/mittelgruppe/...);
# keep them inside the preview. Shared assets (/assets/...) stay untouched.
find _site/new -name '*.html' -print0 | xargs -0 sed -i -E \
  's#href="/(mittelgruppe|suedgruppe|impressum|20[0-9]{2}/)#href="/new/\1#g'

# Static search: index the finished /new pages (only elements marked data-pagefind-body are indexed).
# The version is pinned so builds stay reproducible.
PAGEFIND_VERSION=1.5.2
npx --yes "pagefind@${PAGEFIND_VERSION}" --site _site/new --quiet

echo "Built _site/ ($(find _site -type f | wc -l) files)"
