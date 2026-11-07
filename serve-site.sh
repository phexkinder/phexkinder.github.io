#!/usr/bin/env bash
# Builds the complete site (like the deploy does) and serves it locally, so you can look at a change
# before it is merged:
#
#   ./serve-site.sh            build, then open http://localhost:4000/   (and /old/ for the old design)
#   ./serve-site.sh --no-build serve the last build again (after editing nothing)
#   PORT=8080 ./serve-site.sh  another port
#
# Needs Ruby, Bundler and Node.js (see README). Stop the server with Ctrl+C. A change to the sources
# needs a new run of the script: stop it and start it again.
set -euo pipefail
cd "$(dirname "$0")"

port="${PORT:-4000}"
[ "${1:-}" = "--no-build" ] || ./build-site.sh
[ -d _site ] || { echo "No _site/ yet: run ./serve-site.sh without --no-build first." >&2; exit 1; }

echo
echo "Site:  http://localhost:${port}/"
echo "Old:   http://localhost:${port}/old/"
echo "(Ctrl+C to stop)"
echo
cd _site
if command -v python3 > /dev/null; then
  exec python3 -m http.server "$port" --bind 127.0.0.1
else
  exec ruby -run -e httpd . -b 127.0.0.1 -p "$port"
fi
