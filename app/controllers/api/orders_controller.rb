module Api
  class OrdersController < ApplicationController
    before_action :set_request_data

    def create
      request = OrderRequest.new(
        user_credentials: params[:credentials],
        order_data: params[:order],
        ip_address: request.remote_ip,
        session_id: session.id
      )

      processor = OrderProcessor.new
      result = processor.process_order(request)

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
    end

    private

    def set_request_data
      Rails.logger.info "Processing request from IP: #{request.remote_ip}"
    end
  end
end
