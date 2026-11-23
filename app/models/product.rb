class Product < ApplicationRecord
  belongs_to :shop
  has_many :order_items, dependent: :restrict_with_error

  validates :title, :sku, presence: true
  validates :sku, uniqueness: { scope: :shop_id }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
