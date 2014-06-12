module Spree
  class AmazonIpnController < BaseController

    protect_from_forgery :except => [:ipn]
    
    def ipn
      
      # Temporarily log the entire request
      logger.error("IPN Notification:\n#{params.to_s}")

      # Verify signature of request
      if SpreeAmazonPayments::AmazonFps.valid_signature?(request)

        # TODO Handle request

      else
        logger.warn("Received IPN notification with invalid signature!")
      end

      render nothing: true
    end

    private

    def off_amazon_payments_client
      SpreeAmazonPayments::OffAmazonPayments.client
    end
  
  end
end