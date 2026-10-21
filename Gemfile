source "https://rubygems.org"

# Jekyll 4 with only the plugins the site uses. The site is built and published by
# .github/workflows/deploy.yml (GitHub Actions), not by the built-in GitHub Pages builder,
# so the `github-pages` gem is not needed. To upgrade: `bundle update`.
gem "jekyll", "~> 4.4"

# Plain gems, not `group :jekyll_plugins`: which plugin runs is decided by `plugins:` in
# _config.yml (whole site) and _config_new.yml (/new preview, which has no sitemap).
gem "jekyll-feed"
gem "jekyll-paginate" # blog index of /new
gem "jekyll-seo-tag"
gem "jekyll-sitemap"

gem "kramdown-parser-gfm" # GitHub-flavoured Markdown, as GitHub Pages used by default

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Needed on Ruby 3.0+, where webrick is no longer bundled
gem "webrick"
