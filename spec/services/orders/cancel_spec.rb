require "rails_helper"

RSpec.describe Orders::Cancel do
  let(:shop) { create(:shop) }
  let(:product) { create(:product, shop: shop, stock: 5) }
  let(:order) do
    Orders::Place.new(shop, { customer_email: "buyer@example.com", items: [ { product_id: product.id, quantity: 2 } ] }).call
  end

  it "cancels a pending order and puts the stock back" do
    Orders::Cancel.new(order).call

    expect(order.reload).to be_cancelled
    expect(product.reload.stock).to eq(5)
  end

  it "does not put stock back twice" do
    Orders::Cancel.new(order).call
    Orders::Cancel.new(order).call

    expect(product.reload.stock).to eq(5)
  end

  it "does not cancel a paid order" do
    order.update!(status: :paid)

    expect { Orders::Cancel.new(order).call }.to raise_error(Orders::Cancel::NotCancellableError)
    expect(product.reload.stock).to eq(3)
  end
end
