class OrdersController < ApplicationController
  def index
    orders = current_shop.orders.includes(:order_items).order(id: :desc)
    render json: orders.map { |order| order_json(order) }
  end

  def show
    order = current_shop.orders.find(params[:id])
    render json: order_json(order)
  end

  def create
    order = Orders::Place.new(current_shop, order_params, request.headers["Idempotency-Key"]).call
    status = order.previously_new_record? ? :created : :ok
    render json: order_json(order), status: status
  rescue Orders::Place::OutOfStockError, Orders::Place::InvalidOrderError => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

  def cancel
    order = current_shop.orders.find(params[:id])
    Orders::Cancel.new(order).call
    render json: order_json(order)
  rescue Orders::Cancel::NotCancellableError => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

  private

  def order_params
    params.require(:order).permit(:customer_email, items: [ :product_id, :quantity ])
  end

  def order_json(order)
    {
      id: order.id,
      customer_email: order.customer_email,
      status: order.status,
      total_cents: order.total_cents,
      paid_at: order.paid_at,
      created_at: order.created_at,
      items: order.order_items.map do |item|
        { product_id: item.product_id, quantity: item.quantity, unit_price_cents: item.unit_price_cents }
      end
    }
  end
end
