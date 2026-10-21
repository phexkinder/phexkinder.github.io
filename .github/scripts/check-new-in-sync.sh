#!/usr/bin/env bash
# Rebuilds the /new preview and fails if the committed new/ folder differs from the result.
# Ignored: the <updated> timestamp in new/feed.xml (changes on every build) and the file names inside
# new/pagefind/ (Pagefind numbers its index files in directory-walk order, so they differ between machines).
# The search index is checked by its page count instead.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

./build-new.sh

strip_updated() { sed -E 's#<updated>[^<]*</updated>##g' "$1"; }

# Restore the committed feed so only real differences remain, then compare ignoring timestamps.
committed=$(mktemp)
git show HEAD:new/feed.xml > "$committed"
if ! diff -q <(strip_updated "$committed") <(strip_updated new/feed.xml) > /dev/null; then
  echo "::error::new/feed.xml is out of date."
  stale=1
fi
cp "$committed" new/feed.xml

page_count() { grep -o '"page_count":[0-9]*' "$1"; }
git show HEAD:new/pagefind/pagefind-entry.json > "$committed"
if [ "$(page_count "$committed")" != "$(page_count new/pagefind/pagefind-entry.json)" ]; then
  echo "::error::The search index in new/pagefind/ is out of date (different number of pages)."
  stale=1
fi
# Keep the committed index, so only differences outside it are reported below.
git checkout -- new/pagefind
git clean -fdq -- new/pagefind

if [ -n "$(git status --porcelain -- new)" ] || [ "${stale:-0}" = 1 ]; then
  echo "::error::new/ is out of sync with the sources. Run ./build-new.sh and commit new/."
  git status --short -- new | head -20
  exit 1
fi
echo "new/ is in sync."
