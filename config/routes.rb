Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :amazon_payments_settings
  end
  devise_scope :spree_user do 
    get '/amazon-login', :to => 'amazon_login#login', :as => :amazon_login
  end
  put '/amazon-payments/checkout/update/:state', :to => 'amazon_checkout#update', :as => :amazon_checkout_update
  get '/amazon-payments/checkout/:state', :to => 'amazon_checkout#show', :as => :amazon_checkout_state
  get '/amazon-payments/checkout', :to => 'amazon_checkout#show', :as => :amazon_checkout
end
