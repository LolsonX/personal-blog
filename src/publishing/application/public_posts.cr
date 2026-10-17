module Publishing
  class PublicPosts
    def initialize(@repository : Application::PostRepository)
    end

    def latest(limit : Int32 = 5) : Array(Post)
      @repository.latest_published(limit.clamp(1, 50))
    end

    def find(slug : String) : Post?
      normalized_slug = slug.downcase
      return nil unless normalized_slug.matches?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)

      @repository.find_published(normalized_slug)
    end
  end
end
