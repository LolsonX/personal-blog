module Publishing
  module Application
    alias PostRow = NamedTuple(
      id: Int64,
      title: String,
      slug: String,
      summary: String,
      body_markdown: String,
      status: String,
      first_published_at: Int64?,
      slug_frozen: Int64,
      created_at: Int64,
      updated_at: Int64)

    alias CategoryRow = NamedTuple(id: Int64, name: String, slug: String)

    # Storage adapter port. Adapters translate these operations to their database.
    abstract class PostAdapter
      abstract def posts : Array(PostRow)
      abstract def latest_published(limit : Int32) : Array(PostRow)
      abstract def find_published(slug : String) : PostRow?
      abstract def find_post(id : Int64) : PostRow?
      abstract def categories_for_post(post_id : Int64) : Array(CategoryRow)
      abstract def categories : Array(CategoryRow)
      abstract def create_draft(title : String, slug : String, summary : String, body_markdown : String, category_ids : Array(Int64)) : Int64
      abstract def save_post(post : PostRow, category_ids : Array(Int64)) : Bool
      abstract def delete_draft(id : Int64) : Bool
    end
  end
end
