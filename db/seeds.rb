demo_shops = {
  "Maple Apparel" => [ [ "Classic Tee", "TEE-001", 2_500, 20 ], [ "Hoodie", "HOOD-001", 5_500, 5 ] ],
  "Prairie Coffee" => [ [ "Whole Bean 1kg", "BEAN-1KG", 3_200, 12 ], [ "Ceramic Mug", "MUG-001", 1_800, 1 ] ]
}

demo_shops.each do |name, products|
  shop = Shop.find_or_create_by!(name: name)

  products.each do |title, sku, price_cents, stock|
    shop.products.find_or_create_by!(sku: sku) do |product|
      product.title = title
      product.price_cents = price_cents
      product.stock = stock
    end
  end

  puts "#{name}: #{shop.api_token}"
end
