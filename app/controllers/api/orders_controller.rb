module Api
  class OrdersController < ApplicationController
    def create
      order_request = OrderRequest.new(
        user_credentials: params[:credentials] || {},
        order_data: params[:order] || {},
        ip_address: request.remote_ip,  # Aquí request es el objeto Rails HTTP request
        session_id: session.id.to_s
      )

      processor = OrderProcessor.new
      result = processor.process_order(order_request)

      if result.success?
        render json: { 
          success: true, 
          data: result.data, 
          message: result.message 
        }, status: :created
      else
        render json: { 
          success: false, 
          message: result.message, 
          error_code: result.error_code 
        }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Order processing error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      render json: {
        success: false,
        message: "Internal server error: #{e.message}",
        error_code: "INTERNAL_ERROR"
      }, status: :internal_server_error
    end

    private

    def set_request_data
      Rails.logger.info "Processing request from IP: #{request.remote_ip}"
    end
  end
end
