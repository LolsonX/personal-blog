require "../../spec_helper"

describe Publishing::Storage::SQLitePostRepository do
  it "returns published posts with their categories and leaves drafts private" do
    database = publishing_test_database
    begin
      Publishing::Storage::Migrations.apply(database)
      category_id = database.query_one("SELECT id FROM categories WHERE slug = 'programming'", as: Int64)
      now = Time.utc.to_unix

      database.exec(<<-SQL, "A published note", "a-published-note", "A short summary", "## Markdown body", now, now, now)
        INSERT INTO posts (title, slug, summary, body_markdown, status, first_published_at, slug_frozen, created_at, updated_at)
        VALUES (?, ?, ?, ?, 'published', ?, 1, ?, ?)
        SQL
      published_id = database.query_one("SELECT id FROM posts WHERE slug = 'a-published-note'", as: Int64)
      database.exec("INSERT INTO post_categories (post_id, category_id) VALUES (?, ?)", published_id, category_id)

      database.exec(<<-SQL, "Private draft", "private-draft", now, now)
        INSERT INTO posts (title, slug, status, created_at, updated_at)
        VALUES (?, ?, 'draft', ?, ?)
        SQL

      repository = Publishing::Storage::SQLitePostRepository.new(database)
      posts = repository.latest_published(10)

      posts.size.should eq(1)
      posts.first.title.should eq("A published note")
      posts.first.categories.map(&.slug).should eq(["programming"])
      repository.find_published("private-draft").should be_nil
    ensure
      database.close
    end
  end

  it "normalizes public slugs and clamps list limits" do
    database = publishing_test_database
    begin
      Publishing::Storage::Migrations.apply(database)
      repository = Publishing::Storage::SQLitePostRepository.new(database)
      public_posts = Publishing::PublicPosts.new(repository)

      public_posts.find("../../etc/passwd").should be_nil
      public_posts.latest(0).should be_empty
    ensure
      database.close
    end
  end
end
