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

    def self.profile_note(author_name : String) : String
      safe_author_name = HTML.escape(author_name)
      String.build { |io| ECR.embed "src/views/components/profile_note.ecr", io }
    end

    def self.topic_entry(topic : SiteContent::Topic, index : Int32) : String
      number = (index + 1).to_s.rjust(2, '0')
      safe_label = HTML.escape(topic.label)
      safe_title = HTML.escape(topic.title)
      safe_description = HTML.escape(topic.description)
      String.build { |io| ECR.embed "src/views/components/topic_entry.ecr", io }
    end

    def self.latest_writing(title : String, description : String) : String
      safe_title = HTML.escape(title)
      safe_description = HTML.escape(description)
      String.build { |io| ECR.embed "src/views/components/latest_writing.ecr", io }
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

  def self.render_home : String
    title = "#{SiteContent::AUTHOR_NAME} (@#{SiteContent::HANDLE}) — #{SiteContent::NAME}"
    description = SiteContent::DESCRIPTION

    header_html = Components.header(SiteContent::GITHUB_URL, SiteContent::TWITCH_URL)
    hero_html = Components.hero(SiteContent::AUTHOR_GIVEN_NAME, SiteContent::AUTHOR_FAMILY_NAME, SiteContent::HANDLE, SiteContent::ROLE, SiteContent::BIO)
    profile_note_html = Components.profile_note(SiteContent::AUTHOR_NAME)
    topic_entries_html = SiteContent::TOPICS.each_with_index.map { |topic, index| Components.topic_entry(topic, index) }.join
    latest_writing_html = Components.latest_writing(SiteContent::FIRST_POST_TITLE, SiteContent::FIRST_POST_DESCRIPTION)
    footer_html = Components.footer(SiteContent::AUTHOR_NAME, SiteContent::NAME, SiteContent::EMAIL, SiteContent::GITHUB_URL, SiteContent::TWITCH_URL)

    content_html = String.build { |io| ECR.embed "src/views/home.ecr", io }
    render_layout(title, description, content_html)
  end

  private def self.render_layout(title : String, description : String, content_html : String) : String
    safe_title = HTML.escape(title)
    safe_description = HTML.escape(description)
    String.build { |io| ECR.embed "src/views/layout.ecr", io }
  end
end
