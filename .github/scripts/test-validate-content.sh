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
  (cd "$root" && cp -R _posts _authors _stories _data mittelgruppe suedgruppe mittelgruppe.md suedgruppe.md suche.html "$work/site/" && cp -R assets/img "$work/site/assets/")
}

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

fresh_copy; sed -i 's/^author: .*/author: Unbekannt/' "$post";                          expect "unknown post author"        "unknown author 'Unbekannt'"
fresh_copy; sed -i 's/^date: [0-9-]*/date: 1999-01-01/' "$post";                        expect "date differs from file name" "does not match the date in the file name"
fresh_copy; sed -i 's/^layout: post/layout: post\nautor: Taran/' "$post";                expect "typo in a front matter key"  "unknown front matter key 'autor'"
fresh_copy; sed -i 's/^title: /# title: /' "$post";                                    expect "post without a title"        "title is missing"
fresh_copy; sed -i '1d' "$post";                                                         expect "front matter removed"        "no front matter block"
fresh_copy; sed -i 's/^layout: post/layout: page/' "$post";                              expect "wrong layout"                "layout must be 'post'"
fresh_copy; printf '%s\n' '- name: X' '  author: Taran' '  url: /mittelgruppe/taran.html' '  tagline: t' '  image: /assets/img/cards/gibt-es-nicht.jpg' >> "$work/site/_data/characters.yml"
                                                                                         expect "card image missing"          "gibt-es-nicht.jpg does not exist"
fresh_copy; sed -i 's#^permalink: .*#permalink: /mittelgruppe/falsch.html#' "$work/site/mittelgruppe/taran.md"
                                                                                         expect "wrong character permalink"   "permalink must be /mittelgruppe/taran.html"
fresh_copy; sed -i 's#url: /suedgruppe.html#url: /gibt-es-nicht.html#' "$work/site/_data/navigation.yml"
                                                                                         expect "menu entry without a page"   "points to /gibt-es-nicht.html"
fresh_copy; sed -i 's#url: /suche/#url: /gibt-es-nicht/#' "$work/site/_data/navigation.yml"
                                                                                         expect "link entry without a page"   "points to /gibt-es-nicht/"
fresh_copy; rm "$work/site/_authors/taran.md";                                           expect "author without author page"  "has stories but no author page"
fresh_copy; sed -i 's/Wolfhart, Yann\]/Wolfhart, Yann, Brin]/' "$work/site/_data/navigation.yml"
                                                                                         expect "author in two groups"        "is listed in two groups"
fresh_copy; sed -i 's#^permalink: /mittelgruppe/dunkar.html#permalink: /mittelgruppe/dunkar.html\nextra: [#' "$work/site/mittelgruppe/dunkar.md"
                                                                                         expect "broken YAML"                 "not valid YAML"

[ "$failures" -eq 0 ] && echo "All content-validator tests passed." || echo "$failures test(s) failed."
exit "$failures"
