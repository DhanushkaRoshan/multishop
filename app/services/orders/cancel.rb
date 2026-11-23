module Orders
  class Cancel
    class NotCancellableError < StandardError; end

    def initialize(order)
      @order = order
    end

    def call
      @order.with_lock do
        raise NotCancellableError, "Only pending orders can be cancelled" if @order.paid?

        if @order.pending?
          @order.order_items.each do |item|
            item.product.increment!(:stock, item.quantity)
          end
          @order.update!(status: :cancelled)
        end
      end

      @order
    end
  end
end
