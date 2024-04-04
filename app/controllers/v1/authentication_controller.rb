module V1

  class AuthenticationController < ApplicationController
    include AuthenticationHelper
    def login
      # Generate JWT token
      token = generate_jwt_token

      render json: { token: token }
    end
  end
end
