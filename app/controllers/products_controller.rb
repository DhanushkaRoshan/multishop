class ProductsController < ApplicationController
  before_action :set_product, only: [ :show, :update ]

  def index
    products = current_shop.products.order(:id)
    render json: products.map { |product| product_json(product) }
  end

  def show
    render json: product_json(@product)
  end

  def create
    product = current_shop.products.create!(product_params)
    render json: product_json(product), status: :created
  end

  def update
    @product.update!(product_params)
    render json: product_json(@product)
  end

  private

  def set_product
    @product = current_shop.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:title, :sku, :price_cents, :stock)
  end

  def product_json(product)
    product.slice(:id, :title, :sku, :price_cents, :stock)
  end
end
