require "rails_helper"

RSpec.describe "Payment webhooks" do
  let(:order) { create(:order) }
  let(:body) { { id: "evt_123", type: "payment.succeeded", data: { order_id: order.id } }.to_json }

  def deliver(payload = body, signature: sign(payload))
    post "/webhooks/payments", params: payload, headers: { "Content-Type" => "application/json", "X-Signature" => signature }
  end

  def sign(payload)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.configuration.x.payment_webhook_secret, payload)
  end

  it "rejects a request with a bad signature" do
    deliver(signature: "forged")

    expect(response).to have_http_status(:unauthorized)
    expect(WebhookEvent.count).to eq(0)
  end

  it "stores the event and enqueues processing" do
    deliver

    expect(response).to have_http_status(:accepted)
    event = WebhookEvent.sole
    expect(event.external_id).to eq("evt_123")
    expect(ProcessWebhookEventJob.jobs.map { |job| job["args"] }).to eq([ [ event.id ] ])
  end

  it "accepts a duplicate delivery without storing or processing it again" do
    deliver
    ProcessWebhookEventJob.drain

    deliver

    expect(response).to have_http_status(:ok)
    expect(WebhookEvent.count).to eq(1)
    expect(ProcessWebhookEventJob.jobs).to be_empty
    expect(order.reload).to be_paid
  end

  it "re-enqueues a duplicate whose first delivery was never processed" do
    deliver
    Sidekiq::Job.clear_all # simulate the job being lost

    deliver

    expect(response).to have_http_status(:ok)
    expect(ProcessWebhookEventJob.jobs.size).to eq(1)
  end

  it "rejects malformed payloads" do
    deliver("not json")

    expect(response).to have_http_status(:bad_request)
  end
end
