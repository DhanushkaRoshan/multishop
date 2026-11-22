class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :customer_email, null: false
      t.string :status, null: false, default: "pending"
      t.integer :total_cents, null: false
      t.string :idempotency_key
      t.datetime :paid_at
      t.timestamps
    end

    add_index :orders, [ :shop_id, :idempotency_key ], unique: true, where: "idempotency_key IS NOT NULL"
    add_index :orders, [ :shop_id, :status ]

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false
      t.timestamps
    end

    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
  end
end
