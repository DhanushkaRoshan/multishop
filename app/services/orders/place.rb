module Orders
  class Place
    class OutOfStockError < StandardError; end
    class InvalidOrderError < StandardError; end

    def initialize(shop, params, idempotency_key = nil)
      @shop = shop
      @customer_email = params[:customer_email]
      @items = params[:items] || []
      @idempotency_key = idempotency_key.presence
    end

    def call
      if @idempotency_key
        existing_order = @shop.orders.find_by(idempotency_key: @idempotency_key)
        return existing_order if existing_order
      end

      raise InvalidOrderError, "Order must have at least one item" if @items.empty?

      Order.transaction do
        order = @shop.orders.new(customer_email: @customer_email, idempotency_key: @idempotency_key, total_cents: 0)

        @items.sort_by { |item| item[:product_id].to_i }.each do |item|
          add_item(order, item)
        end

        order.save!
        order
      end
    rescue ActiveRecord::RecordNotUnique
      @shop.orders.find_by!(idempotency_key: @idempotency_key)
    end

    private

    def add_item(order, item)
      quantity = item[:quantity].to_i
      raise InvalidOrderError, "Quantity must be greater than 0" if quantity <= 0

      product = @shop.products.lock.find_by(id: item[:product_id])
      raise InvalidOrderError, "Product #{item[:product_id]} not found" if product.nil?
      raise OutOfStockError, "Not enough stock for #{product.sku}" if product.stock < quantity

      product.update!(stock: product.stock - quantity)
      order.order_items.build(product: product, quantity: quantity, unit_price_cents: product.price_cents)
      order.total_cents += product.price_cents * quantity
    end
  end
end
