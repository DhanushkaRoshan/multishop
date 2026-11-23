require "rails_helper"

RSpec.describe Shop do
  it "generates a unique API token on create" do
    shop = create(:shop)
    other_shop = create(:shop)

    expect(shop.api_token).to be_present
    expect(shop.api_token).not_to eq(other_shop.api_token)
  end
end
