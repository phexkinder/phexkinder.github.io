#!/usr/bin/env ruby
# frozen_string_literal: true

# Checks the content of the site (front matter and data files) so typos and broken references fail on the
# pull request instead of silently producing a wrong page. Only the Ruby standard library is needed.
#
#   ruby .github/scripts/validate-content.rb [root-directory]
#
# Errors fail the check; warnings are only shown. Messages use GitHub's annotation syntax, so they appear
# next to the file in the pull request.

require "yaml"
require "date"
require "time"

ROOT = File.expand_path(ARGV[0] || File.join(__dir__, "..", ".."))
Dir.chdir(ROOT)

POST_KEYS = %w[layout title date author description image excerpt categories tags permalink published sitemap].freeze
@errors = 0
@warnings = 0

def error(file, message)
  @errors += 1
  puts "::error file=#{file}::#{message}"
end

def warning(file, message)
  @warnings += 1
  puts "::warning file=#{file}::#{message}"
end

# Returns [front matter hash, body] or nil (after reporting) when the file has no valid front matter.
def front_matter(file)
  raw = File.read(file, encoding: "utf-8")
  match = raw.match(/\A---[ \t]*\r?\n(.*?)\r?\n---[ \t]*\r?\n?/m)
  return error(file, "no front matter block (--- ... ---) at the top of the file") && nil unless match

  data = YAML.safe_load(match[1], permitted_classes: [Date, Time]) || {}
  return error(file, "front matter is not a key/value list") && nil unless data.is_a?(Hash)

  [data, raw[match.end(0)..]]
rescue Psych::Exception => e
  error(file, "front matter is not valid YAML: #{e.message.lines.first.strip}")
  nil
end

def load_yaml(file)
  YAML.safe_load(File.read(file, encoding: "utf-8"), permitted_classes: [Date, Time])
rescue Psych::Exception, Errno::ENOENT => e
  error(file, "cannot read data file: #{e.message.lines.first.strip}")
  nil
end

def slug(title)
  title.downcase.gsub("ü", "ue").gsub("ö", "oe").gsub("ä", "ae").gsub("ß", "ss")
end

def file_for_url_path(path)
  File.exist?(path.sub(%r{\A/}, ""))
end

# A page can be a source file next to its URL (.html or .md), also for folder-style URLs like /suche/.
def page_exists?(url)
  base = url.sub(%r{\A/}, "").chomp("/")
  candidates = [base, base.sub(/\.html\z/, ".md"), "#{base}.html", "#{base}.md", "#{base}/index.html", "#{base}/index.md"]
  candidates.any? { |c| !c.empty? && File.file?(c) }
end

# ---- navigation: groups, their authors and their pages ------------------------------------------------
navigation = load_yaml("_data/navigation.yml") || []
known_authors = []
author_group = {}
navigation.each_with_index do |group, i|
  where = "_data/navigation.yml"
  if group.is_a?(Hash) && !group.key?("children")
    # a plain link: needs a title and the url of an existing page
    unless group["title"].is_a?(String) && group["url"].is_a?(String)
      error(where, "entry #{i + 1} without children needs a title and a url")
      next
    end
    error(where, "menu entry #{group['title']} points to #{group['url']}, but no such page exists") unless page_exists?(group["url"])
    next
  end
  unless group.is_a?(Hash) && group["title"].is_a?(String) && group["authors"].is_a?(Array) && group["children"].is_a?(Array)
    error(where, "entry #{i + 1} needs title, authors (list) and children (list)")
    next
  end
  group["authors"].each do |name|
    if author_group.key?(name)
      error(where, "author #{name} is listed in two groups (#{author_group[name]} and #{group['title']})")
    end
    author_group[name] = group["title"]
    known_authors << name
  end
  group["children"].each do |child|
    unless child.is_a?(Hash) && child["title"].is_a?(String) && child["url"].is_a?(String)
      error(where, "every child of #{group['title']} needs a title and a url")
      next
    end
    url = child["url"]
    exists = url.start_with?("/geschichten/") ? File.exist?("_stories/#{url.split('/')[2]}.md") : page_exists?(url)
    error(where, "menu entry #{group['title']} > #{child['title']} points to #{url}, but no such page exists") unless exists
  end
end
# the stories page of a group is found through the slug of the group title (see _new/layouts/stories.html)
navigation.each do |group|
  next unless group.is_a?(Hash) && group["title"].is_a?(String) && group.key?("children")

  stories = "_stories/#{slug(group['title'])}.md"
  error("_data/navigation.yml", "group #{group['title']} has no stories page #{stories}") unless File.exist?(stories)
end

# ---- posts --------------------------------------------------------------------------------------------
used_authors = Hash.new(0)
Dir["_posts/*.md"].sort.each do |file|
  base = File.basename(file)
  name_match = base.match(/\A(\d{4}-\d{2}-\d{2})-([[:alnum:]-]+)\.md\z/)
  error(file, "file name must look like YYYY-MM-DD-title-with-hyphens.md") unless name_match

  data, = front_matter(file)
  next unless data

  (data.keys - POST_KEYS).each { |key| error(file, "unknown front matter key '#{key}' (typo? allowed: #{POST_KEYS.join(', ')})") }
  error(file, "layout must be 'post'") unless data["layout"] == "post"

  date = data["date"]
  if date.nil?
    error(file, "date is missing")
  else
    day = date.respond_to?(:strftime) ? date.strftime("%Y-%m-%d") : date.to_s[0, 10]
    error(file, "date #{day} does not match the date in the file name (#{name_match[1]})") if name_match && day != name_match[1]
  end

  author = data["author"]
  if author.nil?
    error(file, "author is missing")
  elsif !known_authors.include?(author)
    error(file, "unknown author '#{author}' (known: #{known_authors.join(', ')}; see _data/navigation.yml)")
  else
    used_authors[author] += 1
  end

  unless data["title"].is_a?(String) && !data["title"].strip.empty?
    error(file, "title is missing: every story needs a title: line in its front matter")
  end
  error(file, "description must be text") if data.key?("description") && !data["description"].is_a?(String)
  if data["image"] && !file_for_url_path(data["image"].to_s)
    error(file, "image #{data['image']} does not exist")
  end
end

# ---- author pages -------------------------------------------------------------------------------------
used_authors.each_key do |author|
  page = "_authors/#{author.downcase}.md"
  error(page, "#{author} has stories but no author page #{page}") unless File.exist?(page)
end
Dir["_authors/*.md"].sort.each do |file|
  data, = front_matter(file)
  next unless data

  error(file, "layout must be 'author'") unless data["layout"] == "author"
  error(file, "name '#{data['name']}' is not a known author") unless known_authors.include?(data["name"])
  error(file, "file name must be the lower-case author name (#{data['name'].to_s.downcase}.md)") if File.basename(file, ".md") != data["name"].to_s.downcase
end

# ---- character pages ----------------------------------------------------------------------------------
character_urls = []
Dir["{mittelgruppe,suedgruppe}/*.md"].sort.each do |file|
  data, = front_matter(file)
  next unless data

  dir = File.dirname(file)
  expected = "/#{dir}/#{File.basename(file, '.md')}.html"
  character_urls << data["permalink"]
  error(file, "layout must be 'page'") unless data["layout"] == "page"
  error(file, "title is missing") unless data["title"].is_a?(String) && !data["title"].strip.empty?
  error(file, "permalink must be #{expected}") unless data["permalink"] == expected
  if !known_authors.include?(data["author"])
    error(file, "unknown author '#{data['author']}' (see _data/navigation.yml)")
  elsif slug(author_group[data["author"]]) != dir
    error(file, "#{data['author']} belongs to #{author_group[data['author']]} in _data/navigation.yml but this page is in #{dir}/")
  end
end

# ---- cards and header images --------------------------------------------------------------------------
(load_yaml("_data/characters.yml") || []).each_with_index do |card, i|
  where = "_data/characters.yml"
  %w[name author url tagline].each { |key| error(where, "entry #{i + 1} (#{card['name']}) has no #{key}") unless card[key].is_a?(String) && !card[key].strip.empty? }
  error(where, "#{card['name']}: unknown author '#{card['author']}'") unless known_authors.include?(card["author"])
  error(where, "#{card['name']}: no page with permalink #{card['url']}") unless character_urls.include?(card["url"])
  error(where, "#{card['name']}: image #{card['image']} does not exist") if card["image"] && !file_for_url_path(card["image"])
end
(load_yaml("_data/headers.yml") || []).each do |path|
  error("_data/headers.yml", "header image #{path} does not exist") unless file_for_url_path(path.to_s)
end

puts "Content check: #{@errors} error(s), #{@warnings} warning(s)."
exit(@errors.zero? ? 0 : 1)
