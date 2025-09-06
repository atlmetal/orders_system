class HandlerResponse
  attr_accessor :success, :message, :data, :error_code

  def initialize(success: false, message: "", data: {}, error_code: nil)
    @success = success
    @message = message
    @data = data
    @error_code = error_code
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
