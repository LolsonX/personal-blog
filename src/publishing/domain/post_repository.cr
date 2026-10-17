module Publishing
  abstract class PostRepository
    abstract def latest_published(limit : Int32) : Array(PublishedPost)
    abstract def find_published(slug : String) : PublishedPost?
  end
end
