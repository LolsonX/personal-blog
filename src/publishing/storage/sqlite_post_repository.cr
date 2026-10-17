module Publishing
  module Storage
    class SQLitePostRepository < PostRepository
      PUBLISHED_SELECT = <<-SQL
        SELECT id, title, slug, summary, body_markdown,
               first_published_at, created_at, updated_at
        FROM posts
        WHERE status = 'published'
        SQL

      def initialize(@database : DB::Database)
      end

      def latest_published(limit : Int32) : Array(PublishedPost)
        rows = @database.query_all(
          "#{PUBLISHED_SELECT} ORDER BY first_published_at DESC, id DESC LIMIT ?",
          limit,
          as: {id: Int64, title: String, slug: String, summary: String, body_markdown: String, first_published_at: Int64, created_at: Int64, updated_at: Int64}
        )

        posts = [] of PublishedPost
        rows.each { |row| posts << build_post(row) }
        posts
      end

      def find_published(slug : String) : PublishedPost?
        row = @database.query_one?(
          "#{PUBLISHED_SELECT} AND slug = ? LIMIT 1",
          slug,
          as: {id: Int64, title: String, slug: String, summary: String, body_markdown: String, first_published_at: Int64, created_at: Int64, updated_at: Int64}
        )

        row.try { |found| build_post(found) }
      end

      private def build_post(row : NamedTuple(id: Int64, title: String, slug: String, summary: String, body_markdown: String, first_published_at: Int64, created_at: Int64, updated_at: Int64)) : PublishedPost
        categories = @database.query_all(
          "SELECT c.id, c.name, c.slug FROM categories c INNER JOIN post_categories pc ON pc.category_id = c.id WHERE pc.post_id = ? ORDER BY c.name COLLATE NOCASE",
          row[:id],
          as: {id: Int64, name: String, slug: String}
        )

        PublishedPost.new(
          row[:id],
          row[:title],
          row[:slug],
          row[:summary],
          row[:body_markdown],
          Time.unix(row[:first_published_at]),
          Time.unix(row[:created_at]),
          Time.unix(row[:updated_at]),
          categories.map { |category| Category.new(category[:id], category[:name], category[:slug]) }
        )
      end
    end
  end
end
