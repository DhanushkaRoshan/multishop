module Webhooks
  class PaymentsController < ApplicationController
    skip_before_action :authenticate_shop!
    before_action :verify_signature

    def create
      payload = JSON.parse(request.raw_post)
      event = WebhookEvent.find_by(provider: "payments", external_id: payload["id"])

      if event
        ProcessWebhookEventJob.perform_async(event.id) unless event.processed?
        head :ok
      else
        event = WebhookEvent.create!(provider: "payments", external_id: payload["id"], event_type: payload["type"], payload: payload)
        ProcessWebhookEventJob.perform_async(event.id)
        head :accepted
      end
    rescue ActiveRecord::RecordNotUnique
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def verify_signature
      secret = Rails.configuration.x.payment_webhook_secret
      return head(:unauthorized) if secret.blank?

      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, request.raw_post)
      signature = request.headers["X-Signature"].to_s
      head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(expected, signature)
    end
  end
end
