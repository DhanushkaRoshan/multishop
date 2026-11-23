class Shop < ApplicationRecord
  has_secure_token :api_token

  has_many :products, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :name, presence: true
end
