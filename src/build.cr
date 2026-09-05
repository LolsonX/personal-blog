require "ecr"

site_name = "core-code.net"
status = "portfolio and projects deploying soon"

Dir.mkdir_p("public")
File.open("public/index.html", "w") do |output|
  ECR.embed "src/index.ecr", output
end
