require "kemal"
require "ecr"
require "./database"
require "./site_content"
require "./publishing/domain/category"
require "./publishing/domain/published_post"
require "./publishing/domain/post_repository"
require "./publishing/application/public_posts"
require "./publishing/storage/migrations"
require "./publishing/storage/sqlite_post_repository"
require "./publishing/markdown_renderer"
require "./views"

DEPLOYED_SHA = ({{ env("GIT_SHA") }} || ENV.fetch("GIT_SHA", "local"))
STYLESHEET   = {{ read_file("src/styles/tokens.css") + "\n" + read_file("src/styles/base.css") + "\n" + read_file("src/styles/layout.css") + "\n" + read_file("src/styles/components/header.css") + "\n" + read_file("src/styles/components/hero.css") + "\n" + read_file("src/styles/components/profile-note.css") + "\n" + read_file("src/styles/components/topics.css") + "\n" + read_file("src/styles/components/latest-writing.css") + "\n" + read_file("src/styles/components/post.css") + "\n" + read_file("src/styles/components/footer.css") + "\n" + read_file("src/styles/responsive.css") + "\n" + read_file("src/styles/themes.css") }}

Publishing::Storage::Migrations.apply(Database.connection)
POST_REPOSITORY = Publishing::Storage::SQLitePostRepository.new(Database.connection)
PUBLIC_POSTS    = Publishing::PublicPosts.new(POST_REPOSITORY)

get "/" do
  Views.render_home(PUBLIC_POSTS.latest)
end

get "/writing/:slug" do |env|
  slug = env.params.url["slug"]
  if post = PUBLIC_POSTS.find(slug)
    Views.render_post(post)
  else
    halt env, status_code: 404, response: "Post not found"
  end
end

get "/styles.css" do |env|
  env.response.content_type = "text/css; charset=utf-8"
  env.response.headers["Cache-Control"] = "no-store"
  STYLESHEET
end

get "/deployment" do
  DEPLOYED_SHA
end

get "/health" do |env|
  if Database.healthy?
    "ok"
  else
    halt env, status_code: 503, response: "database unavailable"
  end
end

Database.connection
Kemal.config.host_binding = ENV.fetch("HOST", "0.0.0.0")
Kemal.config.port = ENV.fetch("PORT", "3000").to_i
Kemal.run
