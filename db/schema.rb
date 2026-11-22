# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_27_000004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.check_constraint "quantity > 0", name: "order_items_quantity_positive"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "customer_email", null: false
    t.string "status", default: "pending", null: false
    t.integer "total_cents", null: false
    t.string "idempotency_key"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "idempotency_key"], name: "index_orders_on_shop_id_and_idempotency_key", unique: true, where: "(idempotency_key IS NOT NULL)"
    t.index ["shop_id", "status"], name: "index_orders_on_shop_id_and_status"
    t.index ["shop_id"], name: "index_orders_on_shop_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "title", null: false
    t.string "sku", null: false
    t.integer "price_cents", null: false
    t.integer "stock", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "sku"], name: "index_products_on_shop_id_and_sku", unique: true
    t.index ["shop_id"], name: "index_products_on_shop_id"
    t.check_constraint "price_cents >= 0", name: "products_price_non_negative"
    t.check_constraint "stock >= 0", name: "products_stock_non_negative"
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.string "api_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_shops_on_api_token", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.string "provider", null: false
    t.string "external_id", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "external_id"], name: "index_webhook_events_on_provider_and_external_id", unique: true
  end

  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "shops"
  add_foreign_key "products", "shops"
end
