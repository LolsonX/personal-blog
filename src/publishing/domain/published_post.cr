module Publishing
  record PublishedPost,
    id : Int64,
    title : String,
    slug : String,
    summary : String,
    body_markdown : String,
    first_published_at : Time,
    created_at : Time,
    updated_at : Time,
    categories : Array(Category)
end
