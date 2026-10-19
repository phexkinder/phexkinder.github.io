#!/usr/bin/env bash
# Fails if files that must never be published end up in this (public) repository:
# WordPress configs and database dumps, archives, keys, soundtrack mp3s, very large files.
# Remove a pattern here on purpose if you really want to publish such a file.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

pattern='(^|/)wp-config|\.sql(\.gz)?$|\.(zip|tar|tgz|gz|7z|rar)$|(^|/)\.env|\.(pem|key|p12)$|(^|/)id_(rsa|ed25519)|\.mp3$|\.exe$'
status=0

bad=$(git ls-files | grep -iE "$pattern" || true)
if [ -n "$bad" ]; then
  echo "::error::Files that must not be published were found:"
  echo "$bad"
  status=1
fi

big=$(git ls-files -z | xargs -0 du -k | awk '$1 > 10240 {print $2 " (" int($1/1024) " MB)"}' || true)
if [ -n "$big" ]; then
  echo "::error::Files larger than 10 MB:"
  echo "$big"
  status=1
fi

[ "$status" -eq 0 ] && echo "No forbidden or oversized files."
exit "$status"
