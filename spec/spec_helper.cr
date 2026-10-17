require "spec"
require "db"
require "sqlite3"
require "../src/publishing/domain/category"
require "../src/publishing/domain/post"
require "../src/publishing/application/post_adapter"
require "../src/publishing/application/post_repository"
require "../src/publishing/application/public_posts"
require "../src/publishing/application/manage_posts"
require "../src/publishing/storage/migrations"
require "../src/publishing/storage/sqlite_post_adapter"
require "../src/publishing/markdown_renderer"
require "../src/admin/authentication"

def publishing_test_database : DB::Database
  DB.open("sqlite3://%3Amemory%3A")
end
