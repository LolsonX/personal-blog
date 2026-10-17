require "../spec_helper"

describe Publishing::MarkdownRenderer do
  it "renders Markdown while omitting raw HTML and unsafe links" do
    source = <<-MARKDOWN
      # Hello

      <script>alert(1)</script>

      [unsafe](javascript:alert(1))
      MARKDOWN

    html = Publishing::MarkdownRenderer.render(source)

    html.should contain("<h1>Hello</h1>")
    html.should_not contain("<script>")
    html.should_not contain("javascript:")
  end
end
