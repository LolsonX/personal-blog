require "html"

module Admin
  module Views
    def self.login(csrf_token : String, error : String? = nil) : String
      safe_csrf_token = HTML.escape(csrf_token)
      safe_error = error.try { |message| HTML.escape(message) }
      String.build { |io| ECR.embed "src/views/admin/login.ecr", io }
    end

    def self.dashboard(posts : Array(Publishing::Post), csrf_token : String) : String
      safe_csrf_token = HTML.escape(csrf_token)
      safe_posts = posts.map do |post|
        {
          id:      post.id,
          title:   HTML.escape(post.title),
          slug:    HTML.escape(post.slug),
          status:  post.published? ? "Published" : "Draft",
          updated: HTML.escape(post.updated_at.to_s("%Y-%m-%d %H:%M UTC")),
        }
      end
      String.build { |io| ECR.embed "src/views/admin/dashboard.ecr", io }
    end

    def self.post_form(post : Publishing::Post?, categories : Array(Publishing::Category), csrf_token : String, error : String? = nil, notice : String? = nil) : String
      safe_csrf_token = HTML.escape(csrf_token)
      safe_error = error.try { |message| HTML.escape(message) }
      safe_notice = notice.try { |message| HTML.escape(message) }
      safe_title = HTML.escape(post.try(&.title) || "")
      safe_slug = HTML.escape(post.try(&.slug) || "")
      safe_summary = HTML.escape(post.try(&.summary) || "")
      safe_body = HTML.escape(post.try(&.body_markdown) || "")
      post_id = post.try(&.id)
      form_action = post_id ? "/admin/posts/#{post_id}" : "/admin/posts"
      submit_label = post.try(&.published?) ? "Save changes" : "Save draft"
      slug_locked = post.try(&.slug_frozen) || false
      categories_for_form = categories.map do |category|
        {
          id:      category.id,
          name:    HTML.escape(category.name),
          checked: post.try(&.categories).try(&.any? { |selected| selected.id == category.id }) || false,
        }
      end
      String.build { |io| ECR.embed "src/views/admin/post_form.ecr", io }
    end
  end
end
