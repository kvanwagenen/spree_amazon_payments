require 'peddler'

module SpreeAmazonPayments
  class OffAmazonPayments
    
    # Class method that returns a peddler client
    def self.client
      config = Spree::AmazonPayments::Config
      MWS::OffAmazonPayments.instance_eval{ @path = "/OffAmazonPayments_Sandbox/2013-01-01" }
      MWS.off_amazon_payments(
        marketplace_id: config["marketplace_id"],
        merchant_id: config["seller_id"],
        aws_access_key_id: config["aws_access_key_id"],
        aws_secret_access_key: config["aws_secret_access_key"]
      )
    end

    def purchase

    end

    def authorize

    end    

    def capture

    end

    def void

    end

    def credit

    end

  end
end