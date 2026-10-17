require "base64"

module Publishing
  record ArchivePage, posts : Array(Post), next_cursor : String?

  class PublicPosts
    def initialize(@repository : Application::PostRepository)
    end

    def latest(limit : Int32 = 5) : Array(Post)
      @repository.latest_published(limit.clamp(1, 50))
    end

    def archive(cursor : String? = nil, limit : Int32 = 10) : ArchivePage
      page_size = limit.clamp(1, 50)
      rows = @repository.published_page(page_size + 1, decode_cursor(cursor))
      has_more = rows.size > page_size
      posts = rows.first(page_size)
      next_cursor = if has_more && (last_post = posts.last?)
                      encode_cursor(last_post)
                    end

      ArchivePage.new(posts, next_cursor)
    end

    def find(slug : String) : Post?
      normalized_slug = slug.downcase
      return nil unless normalized_slug.matches?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)

      @repository.find_published(normalized_slug)
    end

    private def decode_cursor(cursor : String?) : Application::PublishedPostCursor?
      return unless cursor

      published_at, id = Base64.decode_string(cursor).split(':', 2)
      raise ArgumentError.new("invalid archive cursor") unless published_at && id && published_at.matches?(/\A\d+\z/) && id.matches?(/\A\d+\z/)

      {published_at: published_at.to_i64, id: id.to_i64}
    rescue
      raise ArgumentError.new("invalid archive cursor")
    end

    private def encode_cursor(post : Post) : String
      Base64.urlsafe_encode("#{post.first_published_at.not_nil!.to_unix}:#{post.id}", padding: false)
    end
  end
end
