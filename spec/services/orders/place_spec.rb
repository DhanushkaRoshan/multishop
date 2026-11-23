require "rails_helper"

RSpec.describe Orders::Place do
  let(:shop) { create(:shop) }
  let(:shirt) { create(:product, shop: shop, price_cents: 2_000, stock: 5) }
  let(:mug) { create(:product, shop: shop, price_cents: 1_500, stock: 2) }

  def place(items, idempotency_key = nil)
    Orders::Place.new(shop, { customer_email: "buyer@example.com", items: items }, idempotency_key).call
  end

  it "creates the order and reduces stock" do
    order = place([ { product_id: shirt.id, quantity: 2 }, { product_id: mug.id, quantity: 1 } ])

    expect(order).to be_persisted
    expect(order).to be_pending
    expect(order.total_cents).to eq(5_500)
    expect(shirt.reload.stock).to eq(3)
    expect(mug.reload.stock).to eq(1)
  end

  it "handles the same product listed twice" do
    place([ { product_id: shirt.id, quantity: 1 }, { product_id: shirt.id, quantity: 2 } ])

    expect(shirt.reload.stock).to eq(2)
  end

  it "rolls back everything when one item is out of stock" do
    expect {
      place([ { product_id: shirt.id, quantity: 1 }, { product_id: mug.id, quantity: 3 } ])
    }.to raise_error(Orders::Place::OutOfStockError)

    expect(Order.count).to eq(0)
    expect(shirt.reload.stock).to eq(5)
  end

  it "does not allow products from another shop" do
    other_product = create(:product, stock: 10)

    expect { place([ { product_id: other_product.id, quantity: 1 } ]) }.to raise_error(Orders::Place::InvalidOrderError)
    expect(other_product.reload.stock).to eq(10)
  end

  it "rejects empty orders and zero quantities" do
    expect { place([]) }.to raise_error(Orders::Place::InvalidOrderError)
    expect { place([ { product_id: shirt.id, quantity: 0 } ]) }.to raise_error(Orders::Place::InvalidOrderError)
  end

  it "returns the same order when the idempotency key is reused" do
    first = place([ { product_id: shirt.id, quantity: 1 } ], "checkout-123")
    second = place([ { product_id: shirt.id, quantity: 1 } ], "checkout-123")

    expect(second).to eq(first)
    expect(shirt.reload.stock).to eq(4)
  end
end
