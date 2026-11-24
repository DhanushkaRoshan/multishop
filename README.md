# MultiShop

A multi-tenant e-commerce backend built with Ruby on Rails. Each shop manages its own products, takes orders and receives payment webhooks through a JSON API.

**Stack:** Rails 8.1 · PostgreSQL · Sidekiq · RSpec

## Key features

- **Tenant isolation.** Each shop signs in with its own API token (`Authorization: Bearer <token>`). Every query starts from the current shop (`current_shop.products.find(id)`), so another shop's records return 404. See [`ApplicationController`](app/controllers/application_controller.rb).
- **No overselling.** [`Orders::Place`](app/services/orders/place.rb) locks each product row (`SELECT ... FOR UPDATE`) inside one transaction before reducing stock. A `CHECK (stock >= 0)` constraint backs this up. [`place_concurrency_spec.rb`](spec/services/orders/place_concurrency_spec.rb) proves it: four buyers race for the last unit and only one succeeds.
- **Safe retries for orders.** Send an `Idempotency-Key` header and a repeated request returns the original order instead of creating a new one.
- **Safe webhook handling.** [`Webhooks::PaymentsController`](app/controllers/webhooks/payments_controller.rb) checks the HMAC signature, ignores duplicate events, and hands work to [`ProcessWebhookEventJob`](app/jobs/process_webhook_event_job.rb). Processing the same event twice does nothing extra, and failed jobs are retried by Sidekiq.
- **Order cancellation.** [`Orders::Cancel`](app/services/orders/cancel.rb) returns stock and is safe to call twice. Paid orders can't be cancelled.

## Data model

```
Shop ─┬─< Product ─┐
      │            │
      └─< Order ──<┴ OrderItem      WebhookEvent
```

Prices are stored in cents.

## Running locally

Requirements: Ruby 3.4 and Docker.

```bash
cp .env.example .env                       # then set your passwords and secrets
docker compose up -d                       # PostgreSQL and Redis
bundle install
bin/rails db:setup                         # prints two demo API tokens
bin/rails server                           # http://localhost:3000
bundle exec sidekiq -C config/sidekiq.yml  # background jobs
```

Run the tests:

```bash
bundle exec rspec
```

## API

| Method | Path | Description |
|---|---|---|
| GET | `/products` | List products |
| GET | `/products/:id` | Show a product |
| POST | `/products` | Create a product |
| PATCH | `/products/:id` | Update a product |
| GET | `/orders` | List orders |
| GET | `/orders/:id` | Show an order |
| POST | `/orders` | Place an order |
| POST | `/orders/:id/cancel` | Cancel a pending order |
| POST | `/webhooks/payments` | Payment webhook (HMAC signed) |

Example:

```bash
curl -X POST localhost:3000/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: checkout-42" \
  -d '{"order": {"customer_email": "sam@example.com", "items": [{"product_id": 1, "quantity": 2}]}}'
```
