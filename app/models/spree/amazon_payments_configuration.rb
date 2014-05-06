module Spree
  class AmazonPaymentsConfiguration < Preferences::Configuration
    preference :seller_id, :string, :default => ''
    preference :client_id, :string, :default => ''
    preference :client_secret, :string, :default => ''
    preference :amazon_mws_endpoint, :string, :default => ''
    preference :widgets_js_url, :string, :default => ''
    preference :profile_api_endpoint, :string, :default => ''
  end
end