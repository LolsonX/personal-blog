require "base64"
require "crypto/bcrypt/password"
require "crypto/subtle"
require "http/cookie"
require "openssl/hmac"
require "random/secure"

module Admin
  record Session, username : String?, csrf_token : String, expires_at : Time do
    def authenticated? : Bool
      !username.nil?
    end
  end

  class Authentication
    COOKIE_NAME = "core_code_editor_session"
    SESSION_TTL = 12.hours

    def initialize(@username : String?, @password_hash : String?, @secret : String?, @secure_cookie : Bool)
    end

    def configured? : Bool
      username_configured = @username.try { |value| !value.empty? && value != "change-me" } || false
      password_configured = @password_hash.try { |value| !value.empty? && value != "change-me" } || false
      secret_configured = @secret.try { |value| value.bytesize >= 32 && value != "change-me" } || false
      username_configured && password_configured && secret_configured
    end

    def valid_credentials?(username : String, password : String) : Bool
      return false unless configured? && username == @username

      Crypto::Bcrypt::Password.new(@password_hash.not_nil!).verify(password)
    rescue Crypto::Bcrypt::Error
      false
    end

    def session(env : HTTP::Server::Context) : Session?
      value = env.request.cookies[COOKIE_NAME]?.try(&.value)
      return unless value

      encoded, signature = value.split('.', 2)
      return unless signature && Crypto::Subtle.constant_time_compare(signature, sign(encoded))

      username, expires_at, csrf_token = Base64.decode_string(encoded).split('|', 3)
      expiry = expires_at.to_i64
      expires = Time.unix(expiry)
      return if expires <= Time.utc
      return unless csrf_token.matches?(/\A[0-9a-f]{64}\z/)

      Session.new(username == "-" ? nil : username, csrf_token, expires)
    rescue
      nil
    end

    def ensure_session(env : HTTP::Server::Context) : Session
      session(env) || issue_session(env, nil)
    end

    def valid_csrf?(session : Session, token : String?) : Bool
      !!token && Crypto::Subtle.constant_time_compare(session.csrf_token, token.not_nil!)
    end

    def issue_session(env : HTTP::Server::Context, username : String?) : Session
      csrf_token = Random::Secure.hex(32)
      expires_at = Time.utc + SESSION_TTL
      raw = "#{username || "-"}|#{expires_at.to_unix}|#{csrf_token}"
      encoded = Base64.urlsafe_encode(raw, padding: false)
      value = "#{encoded}.#{sign(encoded)}"
      env.response.cookies << HTTP::Cookie.new(
        COOKIE_NAME,
        value,
        path: "/",
        expires: expires_at,
        secure: @secure_cookie,
        http_only: true,
        samesite: HTTP::Cookie::SameSite::Lax
      )
      Session.new(username, csrf_token, expires_at)
    end

    def clear_session(env : HTTP::Server::Context) : Nil
      env.response.cookies << HTTP::Cookie.new(
        COOKIE_NAME,
        "",
        path: "/",
        expires: Time.unix(0),
        secure: @secure_cookie,
        http_only: true,
        samesite: HTTP::Cookie::SameSite::Lax
      )
    end

    private def sign(value : String) : String
      OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, @secret.not_nil!, value)
    end
  end
end
