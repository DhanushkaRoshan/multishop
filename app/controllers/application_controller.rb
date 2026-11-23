class ApplicationController < ActionController::API
  before_action :authenticate_shop!

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Not found" }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_content
  end

  rescue_from ActionController::ParameterMissing do |error|
    render json: { errors: [ error.message ] }, status: :bad_request
  end

  private

  attr_reader :current_shop

  def authenticate_shop!
    token = request.headers["Authorization"].to_s.delete_prefix("Bearer ")
    @current_shop = Shop.find_by(api_token: token) if token.present?

    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_shop
  end
end
