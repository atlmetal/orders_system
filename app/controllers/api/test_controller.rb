# app/controllers/api/test_controller.rb
module Api
  class TestController < ApplicationController
    def users
      users = User.all.map do |user|
        {
          email: user.email,
          role: user.role,
          can_create_orders: user.respond_to?(:can_create_orders?) ? user.can_create_orders? : true
        }
      end

      render json: { users: users }
    rescue => e
      render json: { error: e.message, users: [] }
    end

    def reset_cache
      Rails.cache.clear
      render json: { message: "Cache cleared" }
    end

    def reset_brute_force
      Rails.cache.delete_matched("failed_attempts:*")
      render json: { message: "Brute force attempts cleared" }
    end
  end
end
