require "rails_helper"

# Each thread uses its own DB connection, so this spec can't run inside a test transaction.
RSpec.describe Orders::Place, "with concurrent checkouts" do
  self.use_transactional_tests = false

  after do
    OrderItem.delete_all
    Order.delete_all
    Product.delete_all
    Shop.delete_all
  end

  it "sells the last item only once" do
    shop = create(:shop)
    product = create(:product, shop: shop, stock: 1)

    # Slow down the stock update so all four checkouts overlap.
    allow_any_instance_of(Product).to receive(:update!).and_wrap_original do |original, *args|
      sleep 0.1
      original.call(*args)
    end

    threads = 4.times.map do |i|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Orders::Place.new(shop, { customer_email: "buyer#{i}@example.com", items: [ { product_id: product.id, quantity: 1 } ] }).call
          :sold
        rescue Orders::Place::OutOfStockError
          :out_of_stock
        end
      end
    end
    results = threads.map(&:value)

    expect(results.count(:sold)).to eq(1)
    expect(results.count(:out_of_stock)).to eq(3)
    expect(product.reload.stock).to eq(0)
  end
end
