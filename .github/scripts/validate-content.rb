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

def file_for_url_path(path)
  File.exist?(path.sub(%r{\A/}, ""))
end

# A page can be a source file next to its URL (.html or .md), also for folder-style URLs like /suche/.
def page_exists?(url)
  base = url.sub(%r{\A/}, "").chomp("/")
  candidates = [base, base.sub(/\.html\z/, ".md"), "#{base}.html", "#{base}.md", "#{base}/index.html", "#{base}/index.md"]
  candidates.any? { |c| !c.empty? && File.file?(c) }
end

# ---- navigation: groups and their pages ---------------------------------------------------------------
navigation = load_yaml("_data/navigation.yml") || []
group_ids = []
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
  unless group.is_a?(Hash) && group["title"].is_a?(String) && group["id"].is_a?(String) && group["children"].is_a?(Array)
    error(where, "entry #{i + 1} needs title, id (the group name used in the character pages) and children (list)")
    next
  end
  error(where, "group id #{group['id']} is used twice") if group_ids.include?(group["id"])
  group_ids << group["id"]
  group["children"].each do |child|
    unless child.is_a?(Hash) && child["title"].is_a?(String) && child["url"].is_a?(String)
      error(where, "every child of #{group['title']} needs a title and a url")
      next
    end
    url = child["url"]
    exists = url.start_with?("/geschichten/") ? File.exist?("_stories/#{url.split('/')[2]}.md") : page_exists?(url)
    error(where, "menu entry #{group['title']} > #{child['title']} points to #{url}, but no such page exists") unless exists
  end
  # the stories page of a group is found through its id (see _new/layouts/stories.html)
  stories = "_stories/#{group['id']}.md"
  error(where, "group #{group['title']} has no stories page #{stories}") unless File.exist?(stories)
end

# ---- character pages: the single place that says who exists, in which group, and what the cards show --------
CHARACTER_KEYS = %w[layout title author type group status tagline card permalink].freeze
known_authors = []
author_group = {}
Dir["*/*.md"].sort.select { |f| group_ids.include?(File.dirname(f)) }.each do |file|
  data, = front_matter(file)
  next unless data

  dir = File.dirname(file)
  expected = "/#{dir}/#{File.basename(file, '.md')}.html"
  (data.keys - CHARACTER_KEYS).each { |key| error(file, "unknown front matter key '#{key}' (typo? allowed: #{CHARACTER_KEYS.join(', ')})") }
  error(file, "layout must be 'page'") unless data["layout"] == "page"
  error(file, "type must be 'character'") unless data["type"] == "character"
  error(file, "title is missing") unless data["title"].is_a?(String) && !data["title"].strip.empty?
  error(file, "permalink must be #{expected}") unless data["permalink"] == expected
  error(file, "group must be #{dir} (the folder of this page)") unless data["group"] == dir
  error(file, "status must be 'active' or 'former'") unless %w[active former].include?(data["status"])
  error(file, "tagline is missing (the one line shown on cards and in the group list)") unless data["tagline"].is_a?(String) && !data["tagline"].strip.empty?
  error(file, "card image #{data['card']} does not exist") if data["card"] && !file_for_url_path(data["card"].to_s)
  author = data["author"]
  if !author.is_a?(String) || author.strip.empty?
    error(file, "author is missing (the name used in the stories)")
  elsif known_authors.include?(author)
    error(file, "author #{author} is used by two character pages (#{author_group[author]} and #{dir})")
  else
    known_authors << author
    author_group[author] = dir
  end
end

# ---- posts --------------------------------------------------------------------------------------------
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
    error(file, "unknown author '#{author}' (known: #{known_authors.join(', ')}; see the character pages)")
  end

  unless data["title"].is_a?(String) && !data["title"].strip.empty?
    error(file, "title is missing: every story needs a title: line in its front matter")
  end
  error(file, "description must be text") if data.key?("description") && !data["description"].is_a?(String)
  if data["image"] && !file_for_url_path(data["image"].to_s)
    error(file, "image #{data['image']} does not exist")
  end
end

# ---- header images --------------------------------------------------------------------------
(load_yaml("_data/headers.yml") || []).each do |path|
  error("_data/headers.yml", "header image #{path} does not exist") unless file_for_url_path(path.to_s)
end

puts "Content check: #{@errors} error(s), #{@warnings} warning(s)."
exit(@errors.zero? ? 0 : 1)
