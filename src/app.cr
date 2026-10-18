require "kemal"
require "ecr"
require "./database"
require "./site_content"
require "./admin/authentication"
require "./admin/views"
require "./publishing/domain/category"
require "./publishing/domain/post"
require "./publishing/application/post_adapter"
require "./publishing/application/post_repository"
require "./publishing/application/public_posts"
require "./publishing/application/manage_posts"
require "./publishing/storage/migrations"
require "./publishing/storage/sqlite_post_adapter"
require "./publishing/markdown_renderer"
require "./views"

DEPLOYED_SHA = ({{ env("GIT_SHA") }} || ENV.fetch("GIT_SHA", "local"))
FAVICON      = {{ read_file("src/favicon.svg") }}
STYLESHEET   = {{ read_file("src/styles/tokens.css") + "\n" + read_file("src/styles/utilities.css") + "\n" + read_file("src/styles/base.css") + "\n" + read_file("src/styles/layout.css") + "\n" + read_file("src/styles/components/header.css") + "\n" + read_file("src/styles/components/hero.css") + "\n" + read_file("src/styles/components/interests.css") + "\n" + read_file("src/styles/components/latest-writing.css") + "\n" + read_file("src/styles/components/post.css") + "\n" + read_file("src/styles/components/admin.css") + "\n" + read_file("src/styles/components/footer.css") + "\n" + read_file("src/styles/responsive.css") + "\n" + read_file("src/styles/themes.css") }}

database = Database.connection
Publishing::Storage::Migrations.apply(database)
post_adapter = Publishing::Storage::SQLitePostAdapter.new(database)
post_repository = Publishing::Application::PostRepository.new(post_adapter)
public_posts = Publishing::PublicPosts.new(post_repository)
manage_posts = Publishing::Application::ManagePosts.new(post_repository)
editor_auth = Admin::Authentication.new(
  ENV["EDITOR_USERNAME"]?,
  ENV["EDITOR_PASSWORD_HASH"]?,
  ENV["SESSION_SECRET"]?,
  ENV.fetch("COOKIE_SECURE", "true") == "true"
)

before_get "/admin/*" do |env|
  unless env.request.path == "/admin/login" || editor_auth.session(env).try(&.authenticated?)
    env.response.headers["Location"] = "/admin/login"
    halt env, status_code: 302, response: ""
  end
end

before_post "/admin/*" do |env|
  unless env.request.path == "/admin/login" || editor_auth.session(env).try(&.authenticated?)
    env.response.headers["Location"] = "/admin/login"
    halt env, status_code: 302, response: ""
  end
end

get "/admin/login" do |env|
  halt env, status_code: 503, response: "editor is not configured" unless editor_auth.configured?
  session = editor_auth.ensure_session(env)
  Admin::Views.login(session.csrf_token)
end

post "/admin/login" do |env|
  halt env, status_code: 503, response: "editor is not configured" unless editor_auth.configured?
  session = editor_auth.ensure_session(env)
  unless editor_auth.valid_csrf?(session, env.params.body["csrf_token"]?)
    halt env, status_code: 403, response: "invalid form token"
  end

  username = env.params.body["username"]? || ""
  password = env.params.body["password"]? || ""
  if editor_auth.valid_credentials?(username, password)
    editor_auth.issue_session(env, username)
    env.response.headers["Location"] = "/admin"
    halt env, status_code: 303, response: ""
  else
    env.response.status_code = 401
    fresh_session = editor_auth.issue_session(env, nil)
    Admin::Views.login(fresh_session.csrf_token, "Invalid username or password.")
  end
end

get "/admin" do |env|
  session = editor_auth.session(env).not_nil!
  Admin::Views.dashboard(post_repository.all, session.csrf_token)
end

get "/admin/posts/new" do |env|
  session = editor_auth.session(env).not_nil!
  Admin::Views.post_form(nil, post_repository.categories, session.csrf_token)
end

post "/admin/posts" do |env|
  session = editor_auth.session(env).not_nil!
  unless editor_auth.valid_csrf?(session, env.params.body["csrf_token"]?)
    halt env, status_code: 403, response: "invalid form token"
  end

  body = env.params.body
  category_ids = body.fetch_all("category_ids").compact_map(&.to_i64?)
  begin
    post = manage_posts.create(
      body["title"]? || "",
      body["slug"]? || "",
      body["summary"]? || "",
      body["body_markdown"]? || "",
      category_ids,
      body["publish"]? == "true"
    )
    result = post.published? ? "published" : "saved"
    env.response.headers["Location"] = "/admin/posts/#{post.id}/edit?result=#{result}"
    halt env, status_code: 303, response: ""
  rescue ex : ArgumentError
    env.response.status_code = 422
    Admin::Views.post_form(nil, post_repository.categories, session.csrf_token, ex.message)
  rescue ex : DB::Error
    env.response.status_code = 422
    Admin::Views.post_form(nil, post_repository.categories, session.csrf_token, "That slug is already in use.")
  end
end

get "/admin/posts/:id/edit" do |env|
  session = editor_auth.session(env).not_nil!
  id = env.params.url["id"].to_i64?
  post = id.try { |post_id| post_repository.find(post_id) }
  halt env, status_code: 404, response: "Post not found" unless post
  notice = case env.params.query["result"]?
           when "saved"     then "Changes saved."
           when "published" then "Post published."
           else                  nil
           end
  Admin::Views.post_form(post, post_repository.categories, session.csrf_token, notice: notice)
end

post "/admin/posts/:id" do |env|
  session = editor_auth.session(env).not_nil!
  unless editor_auth.valid_csrf?(session, env.params.body["csrf_token"]?)
    halt env, status_code: 403, response: "invalid form token"
  end

  id = env.params.url["id"].to_i64?
  halt env, status_code: 404, response: "Post not found" unless id
  body = env.params.body
  category_ids = body.fetch_all("category_ids").compact_map(&.to_i64?)
  was_published = post_repository.find(id.not_nil!).try(&.published?) || false
  begin
    post = manage_posts.edit(
      id.not_nil!,
      body["title"]? || "",
      body["slug"]? || "",
      body["summary"]? || "",
      body["body_markdown"]? || "",
      category_ids,
      body["publish"]? == "true"
    )
    halt env, status_code: 404, response: "Post not found" unless post
    result = !was_published && post.published? ? "published" : "saved"
    env.response.headers["Location"] = "/admin/posts/#{id}/edit?result=#{result}"
    halt env, status_code: 303, response: ""
  rescue ex : ArgumentError
    env.response.status_code = 422
    current_post = post_repository.find(id.not_nil!)
    Admin::Views.post_form(current_post, post_repository.categories, session.csrf_token, ex.message)
  rescue ex : DB::Error
    env.response.status_code = 422
    current_post = post_repository.find(id.not_nil!)
    Admin::Views.post_form(current_post, post_repository.categories, session.csrf_token, "That slug is already in use.")
  end
end

post "/admin/posts/:id/delete" do |env|
  session = editor_auth.session(env).not_nil!
  unless editor_auth.valid_csrf?(session, env.params.body["csrf_token"]?)
    halt env, status_code: 403, response: "invalid form token"
  end

  id = env.params.url["id"].to_i64?
  halt env, status_code: 400, response: "invalid post id" unless id
  if manage_posts.delete_draft(id.not_nil!)
    env.response.headers["Location"] = "/admin"
    halt env, status_code: 303, response: ""
  else
    halt env, status_code: 409, response: "only drafts can be deleted"
  end
end

post "/admin/logout" do |env|
  session = editor_auth.session(env).not_nil!
  unless editor_auth.valid_csrf?(session, env.params.body["csrf_token"]?)
    halt env, status_code: 403, response: "invalid form token"
  end
  editor_auth.clear_session(env)
  env.response.headers["Location"] = "/admin/login"
  halt env, status_code: 303, response: ""
end

get "/" do
  Views.render_home(public_posts.latest)
end

get "/writing" do |env|
  begin
    Views.render_writing_archive(public_posts.archive(env.params.query["cursor"]?))
  rescue ex : ArgumentError
    halt env, status_code: 400, response: ex.message
  end
end

get "/writing/:slug" do |env|
  slug = env.params.url["slug"]
  if post = public_posts.find(slug)
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

get "/favicon.svg" do |env|
  env.response.content_type = "image/svg+xml; charset=utf-8"
  env.response.headers["Cache-Control"] = "public, max-age=86400"
  FAVICON
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
