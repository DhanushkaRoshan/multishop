require "rails_helper"

RSpec.describe "Orders API" do
  let(:shop) { create(:shop) }
  let(:product) { create(:product, shop: shop, price_cents: 3_000, stock: 2) }

  def create_order(quantity:, headers: {})
    post "/orders",
      params: { order: { customer_email: "buyer@example.com", items: [ { product_id: product.id, quantity: quantity } ] } },
      headers: auth_headers(shop).merge(headers), as: :json
  end

  it "places an order" do
    create_order(quantity: 2)

    expect(response).to have_http_status(:created)
    expect(json).to include("status" => "pending", "total_cents" => 6_000)
    expect(json["items"]).to eq([ { "product_id" => product.id, "quantity" => 2, "unit_price_cents" => 3_000 } ])
  end

  it "returns 422 when there is not enough stock" do
    create_order(quantity: 3)

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["errors"]).to eq([ "Not enough stock for #{product.sku}" ])
  end

  it "replays the original order for a repeated Idempotency-Key" do
    create_order(quantity: 1, headers: { "Idempotency-Key" => "abc" })
    first_id = json["id"]

    create_order(quantity: 1, headers: { "Idempotency-Key" => "abc" })

    expect(response).to have_http_status(:ok)
    expect(json["id"]).to eq(first_id)
    expect(product.reload.stock).to eq(1)
  end

  it "cancels an order and restocks" do
    create_order(quantity: 2)

    post "/orders/#{json['id']}/cancel", headers: auth_headers(shop)

    expect(json["status"]).to eq("cancelled")
    expect(product.reload.stock).to eq(2)
  end

  it "hides another shop's orders" do
    foreign_order = create(:order)

    get "/orders/#{foreign_order.id}", headers: auth_headers(shop)
    expect(response).to have_http_status(:not_found)

    post "/orders/#{foreign_order.id}/cancel", headers: auth_headers(shop)
    expect(response).to have_http_status(:not_found)
  end
end
