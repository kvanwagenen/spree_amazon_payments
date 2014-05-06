Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :amazon_payments_settings
  end
  get '/amazon/login', :to => 'amazon#login', :as => :amazon_login
end
