# app/services/handlers/authorization_handler.rb
module Handlers
  class AuthorizationHandler < BaseHandler
    protected

    def process(request)
      user = request.user

      return error_response('User not found in request', 'USER_NOT_FOUND') unless user

      if user.admin? || user.can_create_orders?
        Rails.logger.info "User authorized: #{user.email}"
        success_response('User authorized successfully')
      else
        Rails.logger.warn "Authorization failed for user: #{user.email}"
        error_response('Insufficient permissions', 'INSUFFICIENT_PERMISSIONS')
      end
    end
  end
end
