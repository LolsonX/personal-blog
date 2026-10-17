# Public-facing site identity and homepage copy.
# Keep editorial content here rather than mixing it into the ECR markup.
module SiteContent
  record Topic, label : String, title : String, description : String

  NAME        = "core-code.net"
  DESCRIPTION = "Notes on Ruby on Rails, Crystal, software development, games, and things worth exploring."

  AUTHOR_GIVEN_NAME  = "Karol"
  AUTHOR_FAMILY_NAME = "Ostrowski"
  AUTHOR_NAME        = "#{AUTHOR_GIVEN_NAME} #{AUTHOR_FAMILY_NAME}"
  HANDLE             = "LolsonX"
  ROLE               = "Independent Ruby on Rails developer"
  BIO                = "I’m a self-employed Ruby on Rails developer with engineering and master’s degrees in Computer Science, and a fan of the Crystal language. Here I share notes on software, games, and the things I’m curious about."

  EMAIL      = "xlolsonx@gmail.com"
  GITHUB_URL = "https://github.com/LolsonX"
  TWITCH_URL = "https://www.twitch.tv/LolsonX"

  TOPICS = [
    Topic.new("Ruby / daily work", "Ruby on Rails & Crystal", "I work professionally with Ruby on Rails and enjoy exploring Crystal—its expressive syntax, performance, and potential."),
    Topic.new("Play / design", "Worlds worth exploring", "Thoughts on games, design, and the details that make an experience stay with you."),
  ]

  FIRST_POST_TITLE       = "The first post is in the works."
  FIRST_POST_DESCRIPTION = "New writing will appear here. In the meantime, this is where the notes, experiments, and finished thoughts will live."
end
