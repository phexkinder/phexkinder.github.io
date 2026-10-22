# frozen_string_literal: true

# One "Geschichten von <Name>" page per character who has written a story (/autor/taran/ ...),
# generated from the character pages (type: character) and the posts, so nothing has to be added by hand.
# Only the /new preview has these pages: it switches the generator on with `author_pages: true`
# in _config_new.yml.
module Phexkinder
  class AuthorPages < Jekyll::Generator
    safe true

    def generate(site)
      return unless site.config["author_pages"]

      with_stories = site.posts.docs.map { |post| post.data["author"] }.uniq
      site.pages.select { |page| page.data["type"] == "character" }.each do |character|
        name = character.data["author"]
        next unless with_stories.include?(name)

        page = Jekyll::PageWithoutAFile.new(site, site.source, File.join("autor", name.downcase), "index.html")
        page.content = ""
        page.data.merge!("layout" => "author", "author" => name, "title" => "Geschichten von #{name}")
        site.pages << page
      end
    end
  end
end
