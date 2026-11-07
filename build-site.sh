#!/usr/bin/env bash
# Builds the whole site into _site/ and the search index into _site/pagefind/.
# GitHub Actions publishes _site/ (see .github/workflows/deploy.yml).
# Needs Ruby/Bundler and Node.js. Run from anywhere:  ./build-site.sh
set -euo pipefail
cd "$(dirname "$0")"

rm -rf _site
${JEKYLL:-bundle exec jekyll} build --config _config.yml

# Static search: index the finished pages (only elements marked data-pagefind-body are indexed).
# The version is pinned so builds stay reproducible.
PAGEFIND_VERSION=1.5.2
npx --yes "pagefind@${PAGEFIND_VERSION}" --site _site --quiet

echo "Built _site/ ($(find _site -type f | wc -l) files)"
