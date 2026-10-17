require "markd"

module Publishing
  module MarkdownRenderer
    OPTIONS = Markd::Options.new(safe: true)

    def self.render(markdown : String) : String
      Markd.to_html(markdown, OPTIONS)
    end
  end
end
