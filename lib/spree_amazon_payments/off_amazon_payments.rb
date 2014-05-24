require 'peddler'

module SpreeAmazonPayments
  class OffAmazonPayments
    def self.client
      config = Spree::AmazonPayments::Config
      MWS.off_amazon_payments(
        marketplace_id: config["marketplace_id"],
        merchant_id: config["seller_id"],
        aws_access_key_id: config["aws_access_key_id"],
        aws_secret_access_key: config["aws_secret_access_key"]
      )
    end
  end
end