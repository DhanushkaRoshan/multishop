class WebhookEvent < ApplicationRecord
  validates :provider, :external_id, :event_type, presence: true

  def processed?
    processed_at.present?
  end
end
