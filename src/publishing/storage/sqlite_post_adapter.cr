module Publishing
  module Storage
    class SQLitePostAdapter < Application::PostAdapter
      POST_ROW = {
        id:                 Int64,
        title:              String,
        slug:               String,
        summary:            String,
        body_markdown:      String,
        status:             String,
        first_published_at: Int64?,
        slug_frozen:        Int64,
        created_at:         Int64,
        updated_at:         Int64,
      }

      def initialize(@database : DB::Database)
      end

      def posts : Array(Application::PostRow)
        @database.query_all(
          "SELECT id, title, slug, summary, body_markdown, status, first_published_at, slug_frozen, created_at, updated_at FROM posts ORDER BY updated_at DESC, id DESC",
          as: POST_ROW
        )
      end

      def latest_published(limit : Int32) : Array(Application::PostRow)
        @database.query_all(
          "SELECT id, title, slug, summary, body_markdown, status, first_published_at, slug_frozen, created_at, updated_at FROM posts WHERE status = 'published' ORDER BY first_published_at DESC, id DESC LIMIT ?",
          limit,
          as: POST_ROW
        )
      end

      def find_published(slug : String) : Application::PostRow?
        @database.query_one?(
          "SELECT id, title, slug, summary, body_markdown, status, first_published_at, slug_frozen, created_at, updated_at FROM posts WHERE status = 'published' AND slug = ? LIMIT 1",
          slug,
          as: POST_ROW
        )
      end

      def find_post(id : Int64) : Application::PostRow?
        @database.query_one?(
          "SELECT id, title, slug, summary, body_markdown, status, first_published_at, slug_frozen, created_at, updated_at FROM posts WHERE id = ? LIMIT 1",
          id,
          as: POST_ROW
        )
      end

      def categories_for_post(post_id : Int64) : Array(Application::CategoryRow)
        @database.query_all(
          "SELECT c.id, c.name, c.slug FROM categories c INNER JOIN post_categories pc ON pc.category_id = c.id WHERE pc.post_id = ? ORDER BY c.name COLLATE NOCASE",
          post_id,
          as: {id: Int64, name: String, slug: String}
        )
      end

      def categories : Array(Application::CategoryRow)
        @database.query_all(
          "SELECT id, name, slug FROM categories ORDER BY name COLLATE NOCASE",
          as: {id: Int64, name: String, slug: String}
        )
      end

      def create_draft(title : String, slug : String, summary : String, body_markdown : String, category_ids : Array(Int64)) : Int64
        now = Time.utc.to_unix
        @database.transaction do |transaction|
          connection = transaction.connection
          connection.exec(
            "INSERT INTO posts (title, slug, summary, body_markdown, status, created_at, updated_at) VALUES (?, ?, ?, ?, 'draft', ?, ?)",
            title, slug, summary, body_markdown, now, now
          )
          id = connection.query_one("SELECT last_insert_rowid()", as: Int64)
          replace_categories(connection, id, category_ids)
          id
        end.not_nil!
      end

      def save_post(post : Application::PostRow, category_ids : Array(Int64)) : Bool
        @database.transaction do |transaction|
          connection = transaction.connection
          connection.exec(
            "UPDATE posts SET title = ?, slug = ?, summary = ?, body_markdown = ?, status = ?, first_published_at = ?, slug_frozen = ?, updated_at = ? WHERE id = ?",
            post[:title], post[:slug], post[:summary], post[:body_markdown], post[:status], post[:first_published_at], post[:slug_frozen], post[:updated_at], post[:id]
          )
          updated = connection.query_one("SELECT changes()", as: Int64) == 1
          next false unless updated

          replace_categories(connection, post[:id], category_ids)
          true
        end || false
      end

      def delete_draft(id : Int64) : Bool
        @database.exec("DELETE FROM posts WHERE id = ? AND status = 'draft'", id)
        @database.scalar("SELECT changes()") == 1
      end

      private def replace_categories(connection : DB::Connection, post_id : Int64, category_ids : Array(Int64)) : Nil
        connection.exec("DELETE FROM post_categories WHERE post_id = ?", post_id)
        category_ids.uniq.each do |category_id|
          connection.exec("INSERT INTO post_categories (post_id, category_id) VALUES (?, ?)", post_id, category_id)
        end
      end
    end
  end
end
