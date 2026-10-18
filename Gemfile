source "https://rubygems.org"

# Use the same Jekyll/theme/plugin versions that GitHub Pages builds the live
# site with, so local previews match production. To upgrade, run
# `bundle update github-pages`.
gem "github-pages", group: :jekyll_plugins

# If you have any plugins, put them here!
group :jekyll_plugins do
  gem "jekyll-feed"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.0" if Gem.win_platform?

# Needed on Ruby 3.0+, where webrick is no longer bundled
gem "webrick"
