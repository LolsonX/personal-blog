require "kemal"

get "/" do
  site_name = "core-code.net"
  status = "portfolio and projects deploying soon"

  render "src/index.ecr"
end

Kemal.run
