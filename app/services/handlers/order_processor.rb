class OrderProcessor
  def initialize
    @chain = OrderChainBuilder.build_chain
  end

  def process_order(request)
    Rails.logger.info "Starting order processing for user: #{request.user_credentials[:email]}"
    validation_result = @chain.handle(request)
    return validation_result if validation_result.failure?

    if validation_result.data[:from_cache]
      return HandlerResponse.new(
        success: true,
        message: 'Order retrieved from cache',
        data: validation_result.data[:cached_data]
      )
    end

    process_new_order(request, validation_result)
  end

  private

  def process_new_order(request, validation_result)
    begin
      order_data = {
        id: SecureRandom.uuid,
        user_id: request.user.id,
        data: request.sanitized_data,
        status: 'pending',
        created_at: Time.current
      }

      Handlers::CacheHandler.cache_response(request.cache_key, order_data)

      Rails.logger.info "Order processed successfully: #{order_data[:id]}"
      HandlerResponse.new(
        success: true,
        message: 'Order created successfully',
        data: order_data
      )
    rescue => e
      Rails.logger.error "Order processing failed: #{e.message}"
      HandlerResponse.new(
        success: false,
        message: "Order processing failed: #{e.message}",
        error_code: 'ORDER_PROCESSING_ERROR'
      )
    end
  end
end
