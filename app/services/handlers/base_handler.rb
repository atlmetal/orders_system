module Handlers
  class BaseHandler
    attr_accessor :next_handler

    def set_next(handler)
      @next_handler = handler
      handler
    end

    def handle(request)
      return process(request) if can_handle?(request)

      if @next_handler
        @next_handler.handle(request)
      else
        HandlerResponse.new(
          success: false,
          message: 'No handler could process the request',
          error_code: 'NO_HANDLER'
        )
      end
    end

    protected

    def process(request)
      raise NotImplementedError, 'Subclasses must implement process method'
    end

    def can_handle?(request)
      true
    end

    def success_response(message = 'Success', data = {})
      HandlerResponse.new(success: true, message: message, data: data)
    end

    def error_response(message, error_code = 'ERROR', data = {})
      HandlerResponse.new(
        success: false,
        message: message,
        error_code: error_code,
        data: data
      )
    end
  end
end