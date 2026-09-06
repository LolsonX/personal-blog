require "kemal"
require "ecr"
require "./database"

SITE_NAME    = "core-code.net"
STATUS       = "portfolio and projects deploying soon"
DEPLOYED_SHA = ({{ env("GIT_SHA") }} || ENV.fetch("GIT_SHA", "local"))

def render_index
  site_name = SITE_NAME
  status = STATUS
  String.build do |io|
    ECR.embed "src/index.ecr", io
  end
end

get "/" do
  render_index
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
