# Phexkinder

Website of a *Das Schwarze Auge* group: stories, characters and their adventures.
Built with [Jekyll](https://jekyllrb.com/) and published with GitHub Pages at <https://www.phexkinder.de/>. A GitHub Actions workflow builds and deploys the site on every push to `master`.

| URL | What it is |
|---|---|
| `https://www.phexkinder.de/` | the current design |
| `https://www.phexkinder.de/new/` | preview of the old WordPress look with modern additions (night mode, cards, new menu). Not indexed by search engines. |

Ideas and planned steps are collected in [issue #20](https://github.com/phexkinder/phexkinder.github.io/issues/20).

## Run it locally

You need Ruby (version in `.ruby-version`) and Bundler; `./build-site.sh` also needs Node.js (it runs the search indexer).

```sh
bundle install
bundle exec jekyll serve      # current design only, at http://localhost:4000/ (quick preview)
./build-site.sh               # the complete site as published: / and /new plus the search index, in _site/
(cd _site && python3 -m http.server 4000)   # look at that result
```

## How the repository is organized

| Path | Purpose |
|---|---|
| `_posts/` | the stories (one Markdown file per story) |
| `mittelgruppe/`, `suedgruppe/`, `*.md` in the root | character pages, group overviews, Impressum |
| `_layouts/`, `_includes/`, `assets/css/site.css` | templates and stylesheet of the **current design** |
| `_new/` | templates (`layouts/`, `includes/`) of the **/new preview** |
| `_config.yml`, `_config_new.yml` | settings for the current design / extra settings for the preview |
| `build-site.sh` | builds both designs and the search index into `_site/` |
| `_data/` | `characters.yml` (cards), `navigation.yml` (/new menu and which authors belong to which group), `headers.yml` (header images) |
| `_authors/`, `_stories/` | one small page per author / per group, used by /new only |
| `suche.html` | the search page of /new (excluded from the main site) |
| `assets/` | images, fonts, stylesheets and scripts |
| `.github/` | CI checks, the deploy workflow and Dependabot settings |

### How the site is built and published

GitHub's built-in Pages builder can only run one Jekyll build, so the site is built by GitHub Actions instead
(`.github/workflows/deploy.yml`, Settings > Pages > Source = "GitHub Actions"). `./build-site.sh` builds the current
design (`_config.yml`) into `_site/`, builds the /new preview on top of it (`_config_new.yml`) into `_site/new/` and
indexes /new for search. Nothing generated is committed: change the sources, open a pull request, merge, and the
workflow publishes the result within a couple of minutes. The same script runs in the pull request checks.

## Search (/new)

`/new/suche/` is a static search ([Pagefind](https://pagefind.app/)): no server, it runs in the visitor's browser. The header
search box and the menu entry "Suche" lead to it.

- `./build-site.sh` builds the index from the finished pages into `_site/new/pagefind/` (about 1.2 MB) on every build; it is not committed.
  The Pagefind version is pinned in the script (`PAGEFIND_VERSION`); to upgrade, change it there.
- Only elements marked `data-pagefind-body` are indexed: the stories and the character and group pages (set in their layouts in
  `_new/layouts/`). Add `data-pagefind-ignore` to leave something out of the index.
- Result titles come from `data-pagefind-meta="title"`. Pagefind filters are not used; stories by author are on the author pages.

## Add a story

Create `_posts/YYYY-MM-DD-short-title.md`:

```markdown
---
layout: post
title: Der Titel der Geschichte
author: Taran        # must match a name in _data/navigation.yml, e.g. Dunkar, Taran, Wolfhart, Yann, Brin
---

First paragraph of the story. <!--more-->   (optional: the home page of /new shows the text up to this marker)

The rest of the story.
```

Every story needs a `title:` line (the check fails without it), because a title cannot be written reliably in a file name
(capitalization, punctuation, umlauts). Optional front matter for nicer link previews when the page is shared:
`description:` and `image:` (a path such as `/assets/img/post-Wald.jpg`).

## Add a character

1. Page `mittelgruppe/<name>.md` with `layout: page`, `title`, `author` (same name as in the stories) and `permalink: /mittelgruppe/<name>.html`.
2. Portrait in `assets/img/`, plus a 360 × 450 px thumbnail `assets/img/cards/<name>.jpg` for the card.
3. Entry in `_data/characters.yml` (card) and the name in the `authors` list of its group in `_data/navigation.yml`.
4. File `_authors/<name>.md` (copy an existing one) for the "Geschichten von …" page.
5. Add the name to the list on the group page (`mittelgruppe.md`). (Nothing to build by hand: the deploy workflow does it.)

## Checks on every pull request

`.github/workflows/check.yml` runs, and you can run the same scripts locally:

- **Forbidden files**: `.github/scripts/forbidden-files.sh` fails on `wp-config*`, SQL dumps, archives, keys, `.env`, `*.mp3`, `*.exe` and files over 10 MB, so material from the old WordPress backup cannot be published by accident (this repository is public).
- **Content** (`ruby .github/scripts/validate-content.rb`): every story has a valid date (matching its file name), a known author and no misspelled front matter keys; character pages, cards, header images and the menu data point to things that exist. `.github/scripts/test-validate-content.sh` proves that each of these mistakes is really caught.
- **Build** of the complete site with `./build-site.sh`, the same script the deploy workflow uses.
- **Internal links and images** in the built site, `/new` included (html-proofer; external links are not checked).

CodeQL, secret scanning with push protection and Dependabot (monthly gem and action updates) are enabled as well.

If a deploy fails, open the failed run under *Actions > Deploy*; *Re-run all jobs* publishes again, and the site stays on its last good version until a deploy succeeds.

## Fonts and licences

- **Mason Serif Bold** (titles in /new): commercial typeface by Emigre / Jonathan Barnbrook. A web-font licence still has to be purchased; Playfair Display (SIL OFL, `assets/fonts/playfair-display-OFL.txt`) is the fallback.
- Droid Serif (Google Fonts) and Playfair Display are self-hosted; the site makes no requests to third parties.
- `assets/css/twentyeleven.css` comes from the WordPress theme Twenty Eleven (GPLv2 or later); `assets/css/site.css` is derived from the minima theme (MIT, notice in the file).
- *Das Schwarze Auge* names, maps and artwork: see the Impressum page for the fan conditions that apply.
