class ApplicationController < ActionController::API
    include AuthenticationHelper

    before_action :authenticate_request

    private
  
    def authenticate_request
        unless request.path == '/v1/login'
            token = request.headers['Authorization']&.split(' ')&.last
            unless token && decode_jwt_token(token)
                Rails.logger.info token
                render json: { error: 'Unauthorized' }, status: :unauthorized
            end
        end
    end
end
