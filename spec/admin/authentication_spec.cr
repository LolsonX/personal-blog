require "../spec_helper"

describe Admin::Authentication do
  it "fails closed when editor secrets are missing or placeholders" do
    auth = Admin::Authentication.new("change-me", "change-me", "change-me", false)
    auth.configured?.should be_false
  end

  it "checks the configured username and bcrypt password" do
    password_hash = Crypto::Bcrypt::Password.create("correct horse", cost: 4).to_s
    auth = Admin::Authentication.new("editor", password_hash, "a" * 64, false)

    auth.configured?.should be_true
    auth.valid_credentials?("editor", "correct horse").should be_true
    auth.valid_credentials?("editor", "wrong password").should be_false
    auth.valid_credentials?("another", "correct horse").should be_false
  end
end
