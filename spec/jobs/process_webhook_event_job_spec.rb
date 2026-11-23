require "rails_helper"

RSpec.describe ProcessWebhookEventJob do
  let(:order) { create(:order) }
  let(:event) { create(:webhook_event, payload: { "id" => "evt_1", "type" => "payment.succeeded", "data" => { "order_id" => order.id } }) }

  it "marks the order paid and the event processed" do
    described_class.new.perform(event.id)

    expect(order.reload).to be_paid
    expect(order.paid_at).to be_present
    expect(event.reload).to be_processed
  end

  it "does nothing the second time the same event is processed" do
    described_class.new.perform(event.id)
    first_paid_at = order.reload.paid_at

    described_class.new.perform(event.id)

    expect(order.reload.paid_at).to eq(first_paid_at)
  end

  it "does not mark a cancelled order as paid" do
    order.update!(status: :cancelled)

    described_class.new.perform(event.id)

    expect(order.reload).to be_cancelled
    expect(event.reload).to be_processed
  end

  it "leaves the event unprocessed when handling fails, so Sidekiq retries it" do
    event.update!(payload: { "data" => { "order_id" => 0 } })

    expect { described_class.new.perform(event.id) }.to raise_error(ActiveRecord::RecordNotFound)
    expect(event.reload).not_to be_processed
  end

  it "ignores event types it does not handle" do
    event.update!(event_type: "payment.created")

    described_class.new.perform(event.id)

    expect(order.reload).to be_pending
    expect(event.reload).to be_processed
  end
end
