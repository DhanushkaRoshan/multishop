FactoryBot.define do
  factory :shop do
    sequence(:name) { |n| "Shop #{n}" }
  end

  factory :product do
    shop
    sequence(:title) { |n| "Product #{n}" }
    sequence(:sku) { |n| "SKU-#{n}" }
    price_cents { 2_500 }
    stock { 10 }
  end

  factory :order do
    shop
    customer_email { "customer@example.com" }
    total_cents { 0 }
  end

  factory :webhook_event do
    provider { "payments" }
    sequence(:external_id) { |n| "evt_#{n}" }
    event_type { "payment.succeeded" }
    payload { {} }
  end
end
