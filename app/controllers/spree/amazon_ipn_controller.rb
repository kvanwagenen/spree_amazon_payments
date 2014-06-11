module Spree
  class AmazonIpnController < BaseController
    
    def ipn
      
      # Temporarily log the entire request
      logger.info("IPN Notification:\n#{params.to_s}")

      # Verify signature of request
      if off_amazon_payments_client.valid_signature?(request)

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