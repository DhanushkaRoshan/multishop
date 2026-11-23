require "rails_helper"

RSpec.describe "Products API" do
  let(:shop) { create(:shop) }
  let(:other_shop) { create(:shop) }

  it "requires an API token" do
    get "/products"

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects an invalid API token" do
    get "/products", headers: { "Authorization" => "Bearer not-a-real-token" }

    expect(response).to have_http_status(:unauthorized)
  end

  describe "tenant isolation" do
    let!(:own_product) { create(:product, shop: shop) }
    let!(:foreign_product) { create(:product, shop: other_shop) }

    it "lists only the authenticated shop's products" do
      get "/products", headers: auth_headers(shop)

      expect(json.pluck("id")).to eq([ own_product.id ])
    end

    it "returns 404 for another shop's product" do
      get "/products/#{foreign_product.id}", headers: auth_headers(shop)

      expect(response).to have_http_status(:not_found)
    end

    it "cannot update another shop's product" do
      patch "/products/#{foreign_product.id}", params: { product: { stock: 0 } }, headers: auth_headers(shop), as: :json

      expect(response).to have_http_status(:not_found)
      expect(foreign_product.reload.stock).to eq(10)
    end
  end

  it "creates a product for the authenticated shop" do
    post "/products", params: { product: { title: "Hoodie", sku: "HOOD-1", price_cents: 4_500, stock: 3 } },
      headers: auth_headers(shop), as: :json

    expect(response).to have_http_status(:created)
    expect(shop.products.sole.sku).to eq("HOOD-1")
  end

  it "returns validation errors" do
    post "/products", params: { product: { title: "", sku: "X", price_cents: -1 } }, headers: auth_headers(shop), as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["errors"]).to include("Title can't be blank")
  end
end
