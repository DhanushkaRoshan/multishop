Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :products, only: [ :index, :show, :create, :update ]
  resources :orders, only: [ :index, :show, :create ] do
    post :cancel, on: :member
  end

  namespace :webhooks do
    resources :payments, only: :create
  end
end
