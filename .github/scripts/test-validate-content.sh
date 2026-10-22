#!/usr/bin/env bash
# Self-test for validate-content.rb: the unchanged content must pass, and each deliberate mistake below
# must be reported. Runs on a temporary copy, so nothing in the repository is touched.
set -uo pipefail
root="$(git rev-parse --show-toplevel)"
validator="$root/.github/scripts/validate-content.rb"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fresh_copy() {
  rm -rf "$work/site"; mkdir -p "$work/site/assets"
  (cd "$root" && cp -R _posts _stories _data mittelgruppe suedgruppe mittelgruppe.md suedgruppe.md suche.html "$work/site/" && cp -R assets/img "$work/site/assets/")
}

# GNU and BSD (macOS) sed differ: BSD needs a backup suffix after -i and does not know \n in a replacement.
# sedi edits the last argument (the file) in place; $nl is a backslash-newline, which both variants accept.
sedi() { sed -i.bak "$@" && rm -f "${@: -1}.bak"; }
nl=$'\\\n'

failures=0
# expect <description> <expected message fragment>   (run after changing the copy in $work/site)
expect() {
  local out status
  out="$(ruby "$validator" "$work/site" 2>&1)"; status=$?
  if [ "$status" -ne 0 ] && grep -qF -- "$2" <<<"$out"; then
    echo "ok   $1"
  else
    echo "FAIL $1 (exit $status, expected message: $2)"; echo "$out" | head -5; failures=$((failures + 1))
  fi
}

fresh_copy
if ruby "$validator" "$work/site" > "$work/clean.txt" 2>&1; then echo "ok   unchanged content passes"; else echo "FAIL unchanged content must pass"; cat "$work/clean.txt"; failures=$((failures + 1)); fi

post="$(ls "$work/site/_posts/"*.md | head -1)"

fresh_copy; sedi 's/^author: .*/author: Unbekannt/' "$post";                          expect "unknown post author"        "unknown author 'Unbekannt'"
fresh_copy; sedi 's/^date: [0-9-]*/date: 1999-01-01/' "$post";                        expect "date differs from file name" "does not match the date in the file name"
fresh_copy; sedi 's/^layout: post/layout: post'"${nl}"'autor: Taran/' "$post";                expect "typo in a front matter key"  "unknown front matter key 'autor'"
fresh_copy; sedi 's/^title: /# title: /' "$post";                                    expect "post without a title"        "title is missing"
fresh_copy; sedi '1d' "$post";                                                         expect "front matter removed"        "no front matter block"
fresh_copy; sedi 's/^layout: post/layout: page/' "$post";                              expect "wrong layout"                "layout must be 'post'"
fresh_copy; sedi 's#^card: .*#card: /assets/img/cards/gibt-es-nicht.jpg#' "$work/site/mittelgruppe/taran.md"
                                                                                         expect "card image missing"          "gibt-es-nicht.jpg does not exist"
fresh_copy; sedi 's#^permalink: .*#permalink: /mittelgruppe/falsch.html#' "$work/site/mittelgruppe/taran.md"
                                                                                         expect "wrong character permalink"   "permalink must be /mittelgruppe/taran.html"
fresh_copy; sedi 's#url: /suedgruppe.html#url: /gibt-es-nicht.html#' "$work/site/_data/navigation.yml"
                                                                                         expect "menu entry without a page"   "points to /gibt-es-nicht.html"
fresh_copy; sedi 's#url: /suche/#url: /gibt-es-nicht/#' "$work/site/_data/navigation.yml"
                                                                                         expect "link entry without a page"   "points to /gibt-es-nicht/"
fresh_copy; sedi 's/^type: character/type: person/' "$work/site/mittelgruppe/taran.md"
                                                                                         expect "character without type"      "type must be 'character'"
fresh_copy; sedi 's/^group: mittelgruppe/group: suedgruppe/' "$work/site/mittelgruppe/taran.md"
                                                                                         expect "wrong group"                 "group must be mittelgruppe"
fresh_copy; sedi 's/^status: active/status: aktiv/' "$work/site/mittelgruppe/taran.md"
                                                                                         expect "unknown status"              "status must be 'active' or 'former'"
fresh_copy; sedi '/^tagline: /d' "$work/site/mittelgruppe/taran.md";                    expect "tagline missing"             "tagline is missing"
fresh_copy; sedi 's/^author: Yann/author: Taran/' "$work/site/mittelgruppe/yann.md";    expect "author on two pages"         "is used by two character pages"
fresh_copy; sedi 's/^tagline: /tagline_: /' "$work/site/mittelgruppe/taran.md";         expect "typo in a character key"     "unknown front matter key 'tagline_'"
fresh_copy; sedi 's/^  id: suedgruppe/  id: sued/' "$work/site/_data/navigation.yml"; expect "group without stories page"  "has no stories page _stories/sued.md"
fresh_copy; sedi 's#^permalink: /mittelgruppe/dunkar.html#permalink: /mittelgruppe/dunkar.html'"${nl}"'extra: [#' "$work/site/mittelgruppe/dunkar.md"
                                                                                         expect "broken YAML"                 "not valid YAML"

[ "$failures" -eq 0 ] && echo "All content-validator tests passed." || echo "$failures test(s) failed."
exit "$failures"
