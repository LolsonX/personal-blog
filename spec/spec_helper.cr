require "spec"
require "db"
require "sqlite3"
require "../src/publishing/domain/category"
require "../src/publishing/domain/published_post"
require "../src/publishing/domain/post_repository"
require "../src/publishing/application/public_posts"
require "../src/publishing/storage/migrations"
require "../src/publishing/storage/sqlite_post_repository"
require "../src/publishing/markdown_renderer"

def publishing_test_database : DB::Database
  DB.open("sqlite3://%3Amemory%3A")
end
