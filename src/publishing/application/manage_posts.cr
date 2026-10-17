module Publishing
  module Application
    class ManagePosts
      def initialize(@repository : PostRepository)
      end

      def create(title : String, slug : String, summary : String, body_markdown : String, category_ids : Array(Int64), publish : Bool) : Post
        post = @repository.create_draft(title, slug, summary, body_markdown, category_ids)
        if publish
          post.publish!
          raise "post could not be saved" unless @repository.save(post)
        end
        post
      end

      def edit(id : Int64, title : String, slug : String, summary : String, body_markdown : String, category_ids : Array(Int64), publish : Bool) : Post?
        post = @repository.find(id)
        return unless post

        categories = @repository.categories
        selected_categories = categories.select { |category| category_ids.includes?(category.id) }
        raise ArgumentError.new("unknown category") unless selected_categories.size == category_ids.uniq.size

        post.edit!(title, slug, summary, body_markdown, selected_categories)
        post.publish! if publish && post.draft?
        raise "post could not be saved" unless @repository.save(post)

        post
      end

      def publish(id : Int64) : Post?
        post = @repository.find(id)
        return unless post

        post.publish!
        raise "post could not be saved" unless @repository.save(post)

        post
      end

      def delete_draft(id : Int64) : Bool
        post = @repository.find(id)
        post && post.draft? ? @repository.delete_draft(id) : false
      end
    end
  end
end
