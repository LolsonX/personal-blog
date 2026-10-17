require "kemal"
require "ecr"
require "./database"
require "./site_content"
require "./views"

DEPLOYED_SHA = ({{ env("GIT_SHA") }} || ENV.fetch("GIT_SHA", "local"))
STYLESHEET   = {{ read_file("src/styles/tokens.css") + "\n" + read_file("src/styles/base.css") + "\n" + read_file("src/styles/layout.css") + "\n" + read_file("src/styles/components/header.css") + "\n" + read_file("src/styles/components/hero.css") + "\n" + read_file("src/styles/components/profile-note.css") + "\n" + read_file("src/styles/components/topics.css") + "\n" + read_file("src/styles/components/latest-writing.css") + "\n" + read_file("src/styles/components/footer.css") + "\n" + read_file("src/styles/responsive.css") + "\n" + read_file("src/styles/themes.css") }}

get "/" do
  Views.render_home
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
