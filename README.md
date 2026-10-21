# Phexkinder

Website of a *Das Schwarze Auge* group: stories, characters and their adventures.
Built with [Jekyll](https://jekyllrb.com/) and published with GitHub Pages at <https://www.phexkinder.de/>.

| URL | What it is |
|---|---|
| `https://www.phexkinder.de/` | the current design |
| `https://www.phexkinder.de/new/` | preview of the old WordPress look with modern additions (night mode, cards, new menu). Not indexed by search engines. |

Ideas and planned steps are collected in [issue #20](https://github.com/phexkinder/phexkinder.github.io/issues/20).

## Run it locally

You need Ruby (version in `.ruby-version`) and Bundler; `./build-new.sh` also needs Node.js (it runs the search indexer).

```sh
bundle install
bundle exec jekyll serve      # current design at http://localhost:4000/
./build-new.sh                # builds the /new preview and its search index into new/ (see below; needs Node.js)
```

## How the repository is organized

| Path | Purpose |
|---|---|
| `_posts/` | the stories (one Markdown file per story) |
| `mittelgruppe/`, `suedgruppe/`, `*.md` in the root | character pages, group overviews, Impressum |
| `_layouts/`, `_includes/`, `assets/css/site.css` | templates and stylesheet of the **current design** |
| `_new/` | templates (`layouts/`, `includes/`) of the **/new preview** |
| `new/` | **generated** output of the /new preview, committed on purpose (see below) |
| `_config.yml`, `_config_new.yml` | settings for the current design / extra settings for the preview |
| `_data/` | `characters.yml` (cards), `navigation.yml` (/new menu and which authors belong to which group), `headers.yml` (header images) |
| `_authors/`, `_stories/` | one small page per author / per group, used by /new only |
| `suche.html` | the search page of /new (excluded from the main site) |
| `assets/` | images, fonts, stylesheets and scripts |
| `.github/` | CI checks and Dependabot settings |

### Why `new/` is committed

GitHub Pages builds the main site by itself, but it can only run one build. The /new preview is therefore
built with `./build-new.sh` (`_config_new.yml` on top of `_config.yml`) and the result is committed in `new/`.
**After changing anything that affects /new** (a post, a character, `_new/`, `_data/`, its CSS), run
`./build-new.sh` and commit `new/` as well. CI fails with a clear message if `new/` is out of date.

## Search (/new)

`/new/suche/` is a static search ([Pagefind](https://pagefind.app/)): no server, it runs in the visitor's browser. The header
search box and the menu entry "Suche" lead to it.

- `./build-new.sh` builds the index from the finished pages into `new/pagefind/` (about 1.2 MB) and `new/` is committed like the
  rest, so the index changes whenever content changes. The Pagefind version is pinned in the script (`PAGEFIND_VERSION`); to upgrade,
  change it, rebuild and commit.
- Only elements marked `data-pagefind-body` are indexed: the stories and the character and group pages (set in their layouts in
  `_new/layouts/`). Add `data-pagefind-ignore` to leave something out of the index.
- Result titles come from `data-pagefind-meta="title"`. Pagefind filters are not used on purpose: with a filter in the index, two builds of the same content are no longer identical, and `new/` must be reproducible for the CI sync check. (Stories by author are on the author pages.)

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
5. Add the name to the list on the group page (`mittelgruppe.md`), then run `./build-new.sh` and commit `new/`.

## Checks on every pull request

`.github/workflows/check.yml` runs, and you can run the same scripts locally:

- **Forbidden files**: `.github/scripts/forbidden-files.sh` fails on `wp-config*`, SQL dumps, archives, keys, `.env`, `*.mp3`, `*.exe` and files over 10 MB, so material from the old WordPress backup cannot be published by accident (this repository is public).
- **Content** (`ruby .github/scripts/validate-content.rb`): every story has a valid date (matching its file name), a known author and no misspelled front matter keys; character pages, cards, header images and the menu data point to things that exist. `.github/scripts/test-validate-content.sh` proves that each of these mistakes is really caught.
- **Build** with the same gems as GitHub Pages (`bundle exec jekyll build`).
- **`new/` in sync**: `.github/scripts/check-new-in-sync.sh`.
- **Internal links and images** (html-proofer; external links are not checked).

CodeQL, secret scanning with push protection and Dependabot (monthly gem and action updates) are enabled as well.

## Fonts and licences

- **Mason Serif Bold** (titles in /new): commercial typeface by Emigre / Jonathan Barnbrook. A web-font licence still has to be purchased; Playfair Display (SIL OFL, `assets/fonts/playfair-display-OFL.txt`) is the fallback.
- Droid Serif (Google Fonts) and Playfair Display are self-hosted; the site makes no requests to third parties.
- `assets/css/twentyeleven.css` comes from the WordPress theme Twenty Eleven (GPLv2 or later); `assets/css/site.css` is derived from the minima theme (MIT, notice in the file).
- *Das Schwarze Auge* names, maps and artwork: see the Impressum page for the fan conditions that apply.
