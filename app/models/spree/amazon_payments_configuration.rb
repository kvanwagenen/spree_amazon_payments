module Spree
  class AmazonPaymentsConfiguration < Preferences::Configuration
    preference :seller_id, :string, :default => ''
    preference :client_id, :string, :default => ''
    preference :client_secret, :string, :default => ''
    preference :amazon_mws_endpoint, :string, :default => ''
    preference :widgets_js_url, :string, :default => ''
    preference :profile_api_endpoint, :string, :default => ''
    preference :marketplace_id, :string, :default => ''
    preference :aws_access_key_id, :string, :default => ''
    preference :aws_secret_access_key, :string, :default => ''
  end
end