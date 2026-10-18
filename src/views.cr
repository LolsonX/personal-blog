require "html"

module Views
  module Components
    def self.header(github_url : String, twitch_url : String) : String
      safe_github_url = HTML.escape(github_url)
      safe_twitch_url = HTML.escape(twitch_url)
      String.build { |io| ECR.embed "src/views/components/header.ecr", io }
    end

    def self.hero(given_name : String, family_name : String, handle : String, role : String, bio : String) : String
      safe_given_name = HTML.escape(given_name)
      safe_family_name = HTML.escape(family_name)
      safe_handle = HTML.escape(handle)
      safe_role = HTML.escape(role)
      safe_bio = HTML.escape(bio)
      String.build { |io| ECR.embed "src/views/components/hero.ecr", io }
    end

    def self.latest_writing(posts : Array(Publishing::Post)) : String
      writing_list(posts, SiteContent::FIRST_POST_TITLE, SiteContent::FIRST_POST_DESCRIPTION)
    end

    def self.writing_list(posts : Array(Publishing::Post), empty_title : String, empty_description : String) : String
      safe_empty_title = HTML.escape(empty_title)
      safe_empty_description = HTML.escape(empty_description)
      safe_posts = posts.select(&.published?).map do |post|
        {
          title:     HTML.escape(post.title),
          slug:      HTML.escape(post.slug),
          summary:   HTML.escape(post.summary),
          published: HTML.escape(post.first_published_at.not_nil!.to_s("%B %-d, %Y")),
        }
      end
      String.build { |io| ECR.embed "src/views/components/latest_writing.ecr", io }
    end

    def self.post_detail(post : Publishing::Post) : String
      safe_title = HTML.escape(post.title)
      safe_summary = HTML.escape(post.summary)
      published_at = post.first_published_at.not_nil!
      safe_published = HTML.escape(published_at.to_s("%B %-d, %Y"))
      safe_published_iso = HTML.escape(published_at.to_s("%Y-%m-%d"))
      rendered_body = Publishing::MarkdownRenderer.render(post.body_markdown)
      String.build { |io| ECR.embed "src/views/components/post_detail.ecr", io }
    end

    def self.footer(author_name : String, site_name : String, email : String, github_url : String, twitch_url : String) : String
      year = Time.local.year
      safe_author_name = HTML.escape(author_name)
      safe_site_name = HTML.escape(site_name)
      safe_email = HTML.escape(email)
      safe_github_url = HTML.escape(github_url)
      safe_twitch_url = HTML.escape(twitch_url)
      String.build { |io| ECR.embed "src/views/components/footer.ecr", io }
    end
  end

  def self.render_home(posts : Array(Publishing::Post)) : String
    title = "#{SiteContent::AUTHOR_NAME} (@#{SiteContent::HANDLE}) — #{SiteContent::NAME}"
    description = SiteContent::DESCRIPTION

    header_html = Components.header(SiteContent::GITHUB_URL, SiteContent::TWITCH_URL)
    hero_html = Components.hero(SiteContent::AUTHOR_GIVEN_NAME, SiteContent::AUTHOR_FAMILY_NAME, SiteContent::HANDLE, SiteContent::ROLE, SiteContent::BIO)
    interests_copy = HTML.escape(SiteContent::INTERESTS)
    latest_writing_html = Components.latest_writing(posts)
    has_published_posts = posts.any?(&.published?)
    footer_html = Components.footer(SiteContent::AUTHOR_NAME, SiteContent::NAME, SiteContent::EMAIL, SiteContent::GITHUB_URL, SiteContent::TWITCH_URL)

    content_html = String.build { |io| ECR.embed "src/views/home.ecr", io }
    render_layout(title, description, content_html)
  end

  def self.render_post(post : Publishing::Post) : String
    title = "#{post.title} — #{SiteContent::NAME}"
    description = post.summary.empty? ? SiteContent::DESCRIPTION : post.summary
    header_html = Components.header(SiteContent::GITHUB_URL, SiteContent::TWITCH_URL)
    post_html = Components.post_detail(post)
    footer_html = Components.footer(SiteContent::AUTHOR_NAME, SiteContent::NAME, SiteContent::EMAIL, SiteContent::GITHUB_URL, SiteContent::TWITCH_URL)
    content_html = String.build { |io| ECR.embed "src/views/post.ecr", io }
    render_layout(title, description, content_html)
  end

  def self.render_writing_archive(page : Publishing::ArchivePage) : String
    title = "Writing — #{SiteContent::NAME}"
    description = "All published notes on software development, Ruby, Crystal, games, and things worth exploring."
    header_html = Components.header(SiteContent::GITHUB_URL, SiteContent::TWITCH_URL)
    writing_list_html = Components.writing_list(page.posts, "No posts yet", "There is nothing in the notebook just yet.")
    next_page_url = page.next_cursor.try { |cursor| "/writing?cursor=#{HTML.escape(cursor)}" }
    footer_html = Components.footer(SiteContent::AUTHOR_NAME, SiteContent::NAME, SiteContent::EMAIL, SiteContent::GITHUB_URL, SiteContent::TWITCH_URL)
    content_html = String.build { |io| ECR.embed "src/views/writing_archive.ecr", io }
    render_layout(title, description, content_html)
  end

  private def self.render_layout(title : String, description : String, content_html : String) : String
    safe_title = HTML.escape(title)
    safe_description = HTML.escape(description)
    String.build { |io| ECR.embed "src/views/layout.ecr", io }
  end
end
