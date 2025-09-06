class OrderProcessor
  def initialize
  end

  def process_order(request)
    Rails.logger.info "Starting basic order processing..."

    return error_response("Missing credentials") if request.user_credentials.empty?

    user = authenticate_user(request.user_credentials)
    return error_response("Invalid credentials", "INVALID_CREDENTIALS") unless user
    return error_response("Insufficient permissions", "INSUFFICIENT_PERMISSIONS") unless user.can_create_orders?
    return error_response("Missing order data") if request.order_data.empty?
    return error_response("Invalid quantity", "SANITIZATION_ERROR") if request.order_data['quantity'].to_i <= 0

    order_data = {
      id: SecureRandom.uuid,
      user_id: user.id,
      data: request.order_data,
      status: 'pending',
      created_at: Time.current
    }

    Rails.logger.info "Order processed successfully: #{order_data[:id]}"

    success_response("Order created successfully", order_data)
  rescue => e
    Rails.logger.error "Order processing failed: #{e.message}"
    error_response("Order processing failed: #{e.message}", "ORDER_PROCESSING_ERROR")
  end

  private

  def authenticate_user(credentials)
    email = credentials[:email] || credentials['email']
    password = credentials[:password] || credentials['password']

    return nil if email.blank? || password.blank?

    User.find_by(email: email, password: password)
  end

  def success_response(message, data = {})
    HandlerResponse.new(success: true, message: message, data: data)
  end

  def error_response(message, error_code = "ERROR")
    HandlerResponse.new(success: false, message: message, error_code: error_code)
  end
end
