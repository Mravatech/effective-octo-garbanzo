module AuthenticationHelper
    SECRET_KEY = Rails.application.secrets.secret_key_base
    identifier = ENV['AUTH_IDENTIFER']

    def generate_jwt_token
        payload = { identifier: identifier } # your identifier
        JWT.encode(payload, SECRET_KEY, 'HS256')
    end

    def decode_jwt_token(token)
        JWT.decode(token, SECRET_KEY, true, algorithm: 'HS256').first
    rescue JWT::DecodeError
        nil
    end
end
