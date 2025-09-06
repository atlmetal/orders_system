class OrderRequest
  attr_accessor :user_credentials, :order_data, :ip_address, 
                :timestamp, :session_id, :user, :sanitized_data

  def initialize(params = {})
    @user_credentials = params[:user_credentials] || {}
    @order_data = params[:order_data] || {}
    @ip_address = params[:ip_address]
    @timestamp = params[:timestamp] || Time.current
    @session_id = params[:session_id]
    @user = nil
    @sanitized_data = nil
  end

  def cache_key
    require 'digest'
    Digest::SHA256.hexdigest("#{user_credentials}#{order_data}")
  end
end
