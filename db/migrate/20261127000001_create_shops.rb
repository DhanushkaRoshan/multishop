class CreateShops < ActiveRecord::Migration[8.1]
  def change
    create_table :shops do |t|
      t.string :name, null: false
      t.string :api_token, null: false
      t.timestamps
    end

    add_index :shops, :api_token, unique: true
  end
end
