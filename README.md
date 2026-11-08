# Phexkinder

Website of a *Das Schwarze Auge* group: stories, characters and their adventures.
Built with [Jekyll](https://jekyllrb.com/) and published with GitHub Pages at <https://www.phexkinder.de/>. A GitHub Actions workflow builds and deploys the site on every push to `master`.

| URL | What it is |
|---|---|
| `https://www.phexkinder.de/` | the site: the look of the old WordPress site (Twenty Eleven) with modern additions (night mode, character cards, new menu, search) |
| `https://www.phexkinder.de/old/` | the former minima-based design, kept as an archive. Not indexed by search engines (`noindex`, `robots.txt`), without search, character cards and menu. |
| `https://www.phexkinder.de/font-test/` | the whole site with the titles in Uncial Antiqua (capitals) instead of Mason Serif, to compare the two. Not indexed, without search. Remove it again (see below) once the font is chosen. |

Ideas and planned steps are collected in [issue #20](https://github.com/phexkinder/phexkinder.github.io/issues/20).

## Run it locally

You need Ruby (version in `.ruby-version`) and Bundler; `./build-site.sh` also needs Node.js (it runs the search indexer).

```sh
bundle install                # once
./serve-site.sh               # builds everything and serves it at http://localhost:4000/ (Ctrl+C to stop)
```

Open <http://localhost:4000/> (the old design is at <http://localhost:4000/old/>). This is exactly what the deploy publishes (the site plus the search index), so use it to
look at a change, also a pull request
(`git fetch && git checkout <branch>`), before merging. After editing something, stop the script and run it again.
`./build-site.sh` only builds into `_site/` without serving; `PORT=8080 ./serve-site.sh` uses another port.
`bundle exec jekyll serve` is a quicker preview, but it does not include the search.

## How the repository is organized

| Path | Purpose |
|---|---|
| `_posts/` | the stories (one Markdown file per story) |
| `mittelgruppe/`, `suedgruppe/` | the **character pages**: one file per character, the single place for name, group, tagline and card image |
| `mittelgruppe.md`, `suedgruppe.md`, `impressum.md` | group overviews, Impressum |
| `_layouts/`, `_includes/` | templates of the site |
| `_old/` | templates (`layouts/`, `includes/`) of the **/old copy**, plus `assets/css/site.css` and `old-index.md` (its home page) |
| `_config.yml`, `_config_old.yml` | settings of the site / extra settings for the /old copy |
| `build-site.sh`, `serve-site.sh` | build the site, the /old copy and the search index into `_site/` / build and serve it locally |
| `_data/` | `navigation.yml` (main menu and the groups), `headers.yml` (header images) |
| `_stories/` | one small page per group with its stories |
| `_plugins/` | `author_pages.rb` generates the "Geschichten von …" page of every character with stories |
| `suche.html` | the search page |
| `assets/` | images, fonts, stylesheets and scripts |
| `_originals/` | full-resolution originals of images; **not published**, the web versions in `assets/img/` are made from them with `.github/scripts/make-image.sh` |
| `.github/` | CI checks, the deploy workflow and Dependabot settings |

### How the site is built and published

GitHub's built-in Pages builder can only run one Jekyll build, so the site is built by GitHub Actions instead
(`.github/workflows/deploy.yml`, Settings > Pages > Source = "GitHub Actions"). `./build-site.sh` builds the site
(`_config.yml`) into `_site/`, builds the /old copy on top of it (`_config_old.yml`) into `_site/old/` and
indexes the main site for search. Nothing generated is committed: change the sources, open a pull request, merge, and the
workflow publishes the result within a couple of minutes. The same script runs in the pull request checks.

## Search

`/suche/` is a static search ([Pagefind](https://pagefind.app/)): no server, it runs in the visitor's browser. The header
search box and the menu entry "Suche" lead to it.

- `./build-site.sh` builds the index from the finished pages into `_site/pagefind/` (about 1.2 MB) on every build; it is not committed.
  The Pagefind version is pinned in the script (`PAGEFIND_VERSION`); to upgrade, change it there.
- Only elements marked `data-pagefind-body` are indexed: the stories and the character and group pages (set in their layouts in
  `_layouts/`). Add `data-pagefind-ignore` to leave something out of the index.
- Result titles come from `data-pagefind-meta="title"`. Pagefind filters are not used; stories by author are on the author pages.

## Add a story

Create `_posts/YYYY-MM-DD-short-title.md`:

```markdown
---
layout: post
title: Der Titel der Geschichte
author: Taran        # must match the author of a character page, e.g. Dunkar, Taran, Wolfhart, Yann, Brin
---

First paragraph of the story. <!--more-->   (optional: the home page shows the text up to this marker)

The rest of the story.
```

Every story needs a `title:` line (the check fails without it), because a title cannot be written reliably in a file name
(capitalization, punctuation, umlauts). Optional front matter for nicer link previews when the page is shared:
`description:` and `image:` (a path such as `/assets/img/post-Wald.jpg`).

## Add a character

1. Page `mittelgruppe/<name>.md` (or `suedgruppe/<name>.md`; the folder is the group) with this front matter:

   ```yaml
   ---
   layout: page
   type: character
   title: Taran
   author: Taran                  # the name used in the stories (author: in the posts)
   group: mittelgruppe            # same as the folder
   status: active                 # active = card and group list, former = only on the page
   tagline: ibn Muhammed …        # one line for the card and the group list
   card: /assets/img/cards/taran.jpg   # optional; without it the card shows a monogram
   permalink: /mittelgruppe/taran.html
   ---
   ```
2. Portrait in `assets/img/`, plus a 360 × 450 px thumbnail `assets/img/cards/<name>.jpg` for the card.

That is all: the card, the group list on the group page, the menu section, the story lists and the author page
(`/autor/<name>/`, once the character has a story) are generated from this page. The content check tells you what is missing.

## Checks on every pull request

`.github/workflows/check.yml` runs, and you can run the same scripts locally:

- **Forbidden files**: `.github/scripts/forbidden-files.sh` fails on `wp-config*`, SQL dumps, archives, keys, `.env`, `*.mp3`, `*.exe` and files over 10 MB, so material from the old WordPress backup cannot be published by accident (this repository is public).
- **Images**: `.github/scripts/check-images.sh` fails on images in `assets/img/` over 500 KB. Keep the full-resolution original in `_originals/` (not published, Jekyll skips folders starting with `_`) and make the web version with `.github/scripts/make-image.sh _originals/<name>.jpg` (900 px wide by default, needs ImageMagick).
- **Content** (`ruby .github/scripts/validate-content.rb`): every story has a valid date (matching its file name), a title, a known author and no misspelled front matter keys; every character page has type, group (= its folder), status, tagline, a unique author and existing card image; header images and the menu data point to things that exist. `.github/scripts/test-validate-content.sh` proves that each of these mistakes is really caught.
- **Build** of the complete site with `./build-site.sh`, the same script the deploy workflow uses.
- **Internal links and images** in the built site (html-proofer; external links are not checked).

CodeQL, secret scanning with push protection and Dependabot (monthly gem and action updates) are enabled as well.

If a deploy fails, open the failed run under *Actions > Deploy*; *Re-run all jobs* publishes again, and the site stays on its last good version until a deploy succeeds.

## Fonts and licences

- **Mason Serif Bold** (titles): commercial typeface by Emigre / Jonathan Barnbrook. A web-font licence still has to be purchased; Playfair Display (SIL OFL, `assets/fonts/playfair-display-OFL.txt`) is the fallback.
- **Uncial Antiqua** (only on /font-test): free (SIL Open Font License, `assets/fonts/uncial-antiqua-OFL.txt`), by Astigmatic; the file is the original from Google Fonts, converted to WOFF2 only. It is a candidate to replace Mason Serif, which would make the licence purchase unnecessary. To adopt it: move the `@font-face` and the title rules of `assets/css/phexkinder-font-test.css` into `phexkinder-custom.css`, delete Mason Serif (`assets/fonts/MasonSerifBold.woff`, its `@font-face` and `font-family` entries), and remove the /font-test copy (`_config_font_test.yml`, the `font_test` conditions in `_layouts/` and `_includes/`, the second `jekyll build` and `font-test` in the loop of `build-site.sh`, the line in `robots.txt`).
- Droid Serif (Google Fonts) and Playfair Display are self-hosted; the site makes no requests to third parties.
- `assets/css/twentyeleven.css` comes from the WordPress theme Twenty Eleven (GPLv2 or later); `assets/css/site.css` (only used by /old) is derived from the minima theme (MIT, notice in the file).
- *Das Schwarze Auge* names, maps and artwork: see the Impressum page for the fan conditions that apply.
