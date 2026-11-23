require "rails_helper"

RSpec.describe Product do
  it "blocks negative stock in the database even when validations are skipped" do
    product = create(:product, stock: 1)

    expect { product.update_column(:stock, -1) }.to raise_error(ActiveRecord::CheckViolation)
  end

  it "allows the same SKU in different shops but not in the same shop" do
    product = create(:product, sku: "TSHIRT")

    expect(build(:product, sku: "TSHIRT")).to be_valid
    expect(build(:product, sku: "TSHIRT", shop: product.shop)).not_to be_valid
  end
end
