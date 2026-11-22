class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :title, null: false
      t.string :sku, null: false
      t.integer :price_cents, null: false
      t.integer :stock, null: false, default: 0
      t.timestamps
    end

    add_index :products, [ :shop_id, :sku ], unique: true
    # Last line of defence: even a buggy code path cannot sell stock that does not exist.
    add_check_constraint :products, "stock >= 0", name: "products_stock_non_negative"
    add_check_constraint :products, "price_cents >= 0", name: "products_price_non_negative"
  end
end
