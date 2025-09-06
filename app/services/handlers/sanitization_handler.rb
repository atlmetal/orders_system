module Handlers
  class SanitizationHandler < BaseHandler
    protected

    def process(request)
      begin
        sanitized_data = sanitize_order_data(request.order_data)
        request.sanitized_data = sanitized_data

        Rails.logger.info 'Data sanitized successfully'
        success_response('Data sanitized successfully', { sanitized_data: sanitized_data })
      rescue => e
        Rails.logger.error "Sanitization failed: #{e.message}"
        error_response("Data sanitization failed: #{e.message}", 'SANITIZATION_ERROR')
      end
    end

    private

    def sanitize_order_data(data)
      sanitized = {}

      data.each do |key, value|
        case value
        when String
          sanitized[key] = ActionController::Base.helpers.sanitize(value.strip)
        when Numeric
          sanitized[key] = value
        when Hash
          sanitized[key] = sanitize_order_data(value)
        else
          sanitized[key] = value.to_s
        end
      end

      validate_required_fields(sanitized)
      sanitized
    end

    def validate_required_fields(data)
      required_fields = %w[product_id quantity price]
      missing_fields = required_fields - data.keys.map(&:to_s)

      raise "Missing required fields: #{missing_fields.join(', ')}" if missing_fields.any?
      raise 'Invalid quantity' if data['quantity'].to_i <= 0
      raise 'Invalid price' if data['price'].to_f <= 0
    end
  end
end
