require "kemal"
require "ecr"
require "./database"
require "./site_content"

DEPLOYED_SHA = ({{ env("GIT_SHA") }} || ENV.fetch("GIT_SHA", "local"))
STYLESHEET   = {{ read_file("src/styles/tokens.css") + "\n" + read_file("src/styles/base.css") + "\n" + read_file("src/styles/layout.css") + "\n" + read_file("src/styles/components.css") + "\n" + read_file("src/styles/themes.css") }}

def render_index
  site_name = SiteContent::NAME
  site_description = SiteContent::DESCRIPTION
  author_name = SiteContent::AUTHOR_NAME
  handle = SiteContent::HANDLE
  role = SiteContent::ROLE
  bio = SiteContent::BIO
  email = SiteContent::EMAIL
  github_url = SiteContent::GITHUB_URL
  twitch_url = SiteContent::TWITCH_URL
  software_topic_title = SiteContent::SOFTWARE_TOPIC_TITLE
  software_topic_description = SiteContent::SOFTWARE_TOPIC_DESCRIPTION
  games_topic_title = SiteContent::GAMES_TOPIC_TITLE
  games_topic_description = SiteContent::GAMES_TOPIC_DESCRIPTION
  first_post_title = SiteContent::FIRST_POST_TITLE
  first_post_description = SiteContent::FIRST_POST_DESCRIPTION
  String.build do |io|
    ECR.embed "src/index.ecr", io
  end
end

get "/" do
  render_index
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
