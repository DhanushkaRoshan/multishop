module ApiHelpers
  def auth_headers(shop)
    { "Authorization" => "Bearer #{shop.api_token}" }
  end

  def json
    response.parsed_body
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
