class CreateWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_events do |t|
      t.string :provider, null: false
      t.string :external_id, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :processed_at
      t.timestamps
    end

    # The provider may deliver the same event more than once; this index makes the second insert fail.
    add_index :webhook_events, [ :provider, :external_id ], unique: true
  end
end
