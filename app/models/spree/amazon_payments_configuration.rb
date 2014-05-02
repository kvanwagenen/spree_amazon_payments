module Spree
  class AmazonPaymentsConfiguration < Preferences::Configuration
    preference :seller_id, :default => ''
    preference :client_id, :default => ''
    preference :client_secret, :default => ''
    preference :amazon_mws_endpoint, :default => ''
    preference :widgets_js_url, :default => ''
    preference :profile_api_endpoint, :default => ''
  end
end