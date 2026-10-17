module Publishing
  enum PostStatus
    Draft
    Published
  end

  class Post
    getter id : Int64
    getter title : String
    getter slug : String
    getter summary : String
    getter body_markdown : String
    getter status : PostStatus
    getter first_published_at : Time?
    getter created_at : Time
    getter updated_at : Time
    getter categories : Array(Category)
    getter slug_frozen : Bool

    def initialize(
      @id : Int64,
      @title : String,
      @slug : String,
      @summary : String,
      @body_markdown : String,
      @status : PostStatus,
      @first_published_at : Time?,
      @created_at : Time,
      @updated_at : Time,
      @categories : Array(Category),
      @slug_frozen : Bool,
    )
      raise ArgumentError.new("post title cannot be blank") if @title.strip.empty?
      raise ArgumentError.new("invalid post slug") unless @slug.matches?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
      raise ArgumentError.new("published posts need a first publication time") if @status.published? && @first_published_at.nil?
      raise ArgumentError.new("a published post's slug must be frozen") if @first_published_at && !@slug_frozen
    end

    def published? : Bool
      @status.published?
    end

    def draft? : Bool
      !published?
    end

    def edit!(title : String, slug : String, summary : String, body_markdown : String, categories : Array(Category), at : Time = Time.utc) : Nil
      raise ArgumentError.new("post title cannot be blank") if title.strip.empty?
      raise ArgumentError.new("invalid post slug") unless slug.matches?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
      raise ArgumentError.new("a published post's slug cannot change") if @slug_frozen && slug != @slug

      @title = title
      @slug = slug
      @summary = summary
      @body_markdown = body_markdown
      @categories = categories
      @updated_at = at
    end

    def publish!(at : Time = Time.utc) : Nil
      unless published?
        @status = PostStatus::Published
        @first_published_at = at
        @slug_frozen = true
      end
      @updated_at = at
    end
  end
end
