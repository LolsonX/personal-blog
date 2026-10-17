require "../../spec_helper"

describe Publishing::Storage::SQLitePostAdapter do
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

      adapter = Publishing::Storage::SQLitePostAdapter.new(database)
      rows = adapter.latest_published(10)

      rows.size.should eq(1)
      rows.first[:title].should eq("A published note")
      rows.first[:status].should eq("published")
      rows.first[:slug_frozen].should eq(1_i64)

      repository = Publishing::Application::PostRepository.new(adapter)
      posts = repository.latest_published(10)
      posts.size.should eq(1)
      posts.first.should be_a(Publishing::Post)
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
      repository = Publishing::Application::PostRepository.new(Publishing::Storage::SQLitePostAdapter.new(database))
      public_posts = Publishing::PublicPosts.new(repository)

      public_posts.find("../../etc/passwd").should be_nil
      public_posts.latest(0).should be_empty
    ensure
      database.close
    end
  end

  it "creates, publishes, edits and only permanently deletes drafts" do
    database = publishing_test_database
    begin
      Publishing::Storage::Migrations.apply(database)
      repository = Publishing::Application::PostRepository.new(Publishing::Storage::SQLitePostAdapter.new(database))
      manager = Publishing::Application::ManagePosts.new(repository)
      category_id = repository.categories.find { |category| category.slug == "programming" }.not_nil!.id

      draft = manager.create("First note", "first-note", "Summary", "Draft body", [category_id], false)
      draft.draft?.should be_true
      draft.slug_frozen.should be_false

      published = manager.edit(draft.id, "First note", "first-note", "Summary", "Published body", [category_id], true).not_nil!
      published.published?.should be_true
      published.slug_frozen.should be_true
      published.first_published_at.should_not be_nil

      expect_raises(ArgumentError, /slug cannot change/) do
        manager.edit(published.id, "First note", "changed-slug", "Summary", "Updated body", [category_id], false)
      end

      manager.delete_draft(published.id).should be_false
      manager.delete_draft(published.id + 100).should be_false

      another_draft = manager.create("Disposable", "disposable", "", "", [] of Int64, false)
      manager.delete_draft(another_draft.id).should be_true
      repository.find(another_draft.id).should be_nil
    ensure
      database.close
    end
  end
end
