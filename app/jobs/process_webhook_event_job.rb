class ProcessWebhookEventJob
  include Sidekiq::Job
  sidekiq_options queue: "webhooks", retry: 10

  def perform(webhook_event_id)
    event = WebhookEvent.find(webhook_event_id)

    event.with_lock do
      unless event.processed?
        mark_order_paid(event) if event.event_type == "payment.succeeded"
        event.update!(processed_at: Time.current)
      end
    end
  end

  private

  def mark_order_paid(event)
    order = Order.find(event.payload.dig("data", "order_id"))

    order.with_lock do
      order.update!(status: :paid, paid_at: Time.current) if order.pending?
    end
  end
end
