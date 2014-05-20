Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :amazon_payments_settings
  end
  devise_scope :spree_user do 
    get '/amazon/login', :to => 'amazon#login', :as => :amazon_login
  end
  get '/amazon/payments/success', :to => 'amazon#payments_success', :as => :amazon_payments_success
  get '/amazon/payments/cancelled', :to => 'amazon#payments_cancelled', :as => :amazon_payments_cancelled
end
