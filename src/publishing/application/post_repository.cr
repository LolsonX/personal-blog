module Publishing
  module Application
    class PostRepository
      def initialize(@adapter : PostAdapter)
      end

      def all : Array(Post)
        @adapter.posts.map { |row| build_post(row) }
      end

      def find(id : Int64) : Post?
        @adapter.find_post(id).try { |row| build_post(row) }
      end

      def categories : Array(Category)
        @adapter.categories.map { |row| Category.new(row[:id], row[:name], row[:slug]) }
      end

      def create_draft(title : String, slug : String, summary : String, body_markdown : String, category_ids : Array(Int64)) : Post
        raise ArgumentError.new("invalid post slug") unless slug.matches?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
        validate_category_ids(category_ids)

        id = @adapter.create_draft(title, slug, summary, body_markdown, category_ids)
        find(id).not_nil!
      end

      def save(post : Post) : Bool
        category_ids = post.categories.map(&.id)
        validate_category_ids(category_ids)
        row = {
          id:                 post.id,
          title:              post.title,
          slug:               post.slug,
          summary:            post.summary,
          body_markdown:      post.body_markdown,
          status:             post.published? ? "published" : "draft",
          first_published_at: post.first_published_at.try(&.to_unix),
          slug_frozen:        post.slug_frozen ? 1_i64 : 0_i64,
          created_at:         post.created_at.to_unix,
          updated_at:         post.updated_at.to_unix,
        }
        @adapter.save_post(row, category_ids)
      end

      def delete_draft(id : Int64) : Bool
        @adapter.delete_draft(id)
      end

      def latest_published(limit : Int32) : Array(Post)
        @adapter.latest_published(limit).map { |row| build_post(row) }
      end

      def find_published(slug : String) : Post?
        @adapter.find_published(slug).try { |row| build_post(row) }
      end

      private def build_post(row : PostRow) : Post
        categories = @adapter.categories_for_post(row[:id]).map do |category|
          Category.new(category[:id], category[:name], category[:slug])
        end

        status = case row[:status]
                 when "draft"     then PostStatus::Draft
                 when "published" then PostStatus::Published
                 else                  raise "unknown post status: #{row[:status]}"
                 end

        Post.new(
          row[:id],
          row[:title],
          row[:slug],
          row[:summary],
          row[:body_markdown],
          status,
          row[:first_published_at].try { |timestamp| Time.unix(timestamp) },
          Time.unix(row[:created_at]),
          Time.unix(row[:updated_at]),
          categories,
          row[:slug_frozen] == 1
        )
      end

      private def validate_category_ids(ids : Array(Int64)) : Nil
        available_ids = categories.map(&.id)
        raise ArgumentError.new("unknown category") unless ids.uniq.all? { |id| available_ids.includes?(id) }
      end
    end
  end
end
