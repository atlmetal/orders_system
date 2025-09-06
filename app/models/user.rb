class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true
  validates :role, inclusion: { in: %w[user admin] }

  def admin?
    role == 'admin'
  end

  def can_create_orders?
    %w[user admin].include?(role)
  end
end