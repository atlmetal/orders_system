module Handlers
  class AuthenticationHandler < BaseHandler
    protected

    def process(request)
      credentials = request.user_credentials

      return error_response('Missing credentials', 'MISSING_CREDENTIALS') if credentials.empty?

      user = authenticate_user(credentials)

      if user
        request.user = user
        Rails.logger.info "User authenticated: #{user.email}"
        success_response('User authenticated successfully', { user: user })
      else
        Rails.logger.warn "Authentication failed for credentials: #{credentials[:email]}"
        error_response('Invalid credentials', 'INVALID_CREDENTIALS')
      end
    end

    private

    def authenticate_user(credentials)
      User.find_by(email: credentials[:email], password: credentials[:password])
    end
  end
end
