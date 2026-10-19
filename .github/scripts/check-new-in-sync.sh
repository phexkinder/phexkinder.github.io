#!/usr/bin/env bash
# Rebuilds the /new preview and fails if the committed new/ folder differs from the result.
# The only thing ignored is the <updated> timestamp in new/feed.xml, which changes on every build.
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

if [ -n "$(git status --porcelain -- new)" ] || [ "${stale:-0}" = 1 ]; then
  echo "::error::new/ is out of sync with the sources. Run ./build-new.sh and commit new/."
  git status --short -- new | head -20
  exit 1
fi
echo "new/ is in sync."
