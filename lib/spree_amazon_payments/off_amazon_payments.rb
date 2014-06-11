require 'peddler'
# require 'httparty'
# require 'jeff'

module SpreeAmazonPayments
  class OffAmazonPayments
    
    # Class method that returns a peddler client
    def self.client
      amazon_payments = Spree::PaymentMethod.find_by_type("Spree::Gateway::AmazonPayments")
      MWS::OffAmazonPayments.instance_eval do 
        @path = "/OffAmazonPayments_Sandbox/2013-01-01"
      end
      client = MWS.off_amazon_payments(
        marketplace_id: amazon_payments.preferred_marketplace_id,
        merchant_id: amazon_payments.preferred_seller_id,
        aws_access_key_id: amazon_payments.preferred_aws_access_key_id,
        aws_secret_access_key: amazon_payments.preferred_aws_secret_access_key
      )
      client.instance_eval do 
        # def set_order_reference_details(order_reference_id, order)
        #   query_params = {
        #     "AWSAccessKeyId" => aws_access_key_id,
        #     "Action" => "SetOrderReferenceDetails",
        #     "AmazonOrderReferenceId" => order_reference_id,
        #     "OrderReferenceAttributes.OrderTotal.Amount" => order.total.to_s,
        #     "OrderReferenceAttributes.OrderTotal.CurrencyCode" => "USD",
        #     "OrderReferenceAttributes.SellerOrderAttributes.SellerOrderId" => order.number,
        #     "SellerId" => merchant_id,
        #     "SignatureMethod" => "HmacSHA256",
        #     "SignatureVersion" => 2,
        #     "Timestamp" => Time.now.utc.iso8601,
        #     "Version" => "2013-01-01"
        #   }
        #   signature = ::Jeff::Signer.new("post", "mws.amazonservices.com", self.class.path, query_params.to_query).sign_with(aws_secret_access_key)
        #   response = HTTParty.post("https://mws.amazonservices.com#{self.class.path}?#{query_params.merge('Signature' => signature).to_query}")
        #   binding.pry
        #   response
        # end

        def set_order_reference_details(amazon_order_reference_id, order_total, currency_code, order_id, opts = {})
          operation('SetOrderReferenceDetails')
            .add(
              'AmazonOrderReferenceId' => amazon_order_reference_id,
              'OrderReferenceAttributes.OrderTotal.Amount' => order_total,
              'OrderReferenceAttributes.OrderTotal.CurrencyCode' => currency_code,
              'OrderReferenceAttributes.SellerOrderAttributes.SellerOrderId' => order_id,
              'Version' => '2013-01-01'
            )

          run
        end

        def authorize(amazon_order_reference_id, authorization_reference_id, authorization_amount_cents, currency_code, opts = {})
          
          # Convert back to dollar value for amazon payments
          authorization_amount = (authorization_amount_cents * 0.01).round(2);

          operation('Authorize')
            .add(opts.merge(
              'AmazonOrderReferenceId' => amazon_order_reference_id,
              'AuthorizationReferenceId' => authorization_reference_id,
              'AuthorizationAmount.Amount' => authorization_amount,
              'AuthorizationAmount.CurrencyCode' => currency_code,
              'Version' => '2013-01-01'
            ))

          run
        end

        def capture(amazon_authorization_id, capture_reference_id, capture_amount, currency_code, opts = {})
          operation('Capture')
            .add(opts.merge(
              'AmazonAuthorizationId' => amazon_authorization_id,
              'CaptureReferenceId' => capture_reference_id,
              'CaptureAmount.Amount' => capture_amount,
              'CaptureAmount.CurrencyCode' => currency_code,
              'Version' => '2013-01-01'
            ))

          run
        end

        def refund(amazon_capture_id, refund_reference_id, refund_amount, currency_code, opts = {})
          operation('Refund')
            .add(opts.merge(
              'AmazonCaptureId' => amazon_capture_id,
              'RefundReferenceId' => refund_reference_id,
              'RefundAmount.Amount' => refund_amount,
              'RefundAmount.CurrencyCode' => currency_code,
              'Version' => '2013-01-01'
            ))

          run
        end

        def get_capture_details(amazon_capture_id)
          operation('GetCaptureDetails')
            .add(
              'AmazonCaptureId' => amazon_capture_id,
              'Version' => '2013-01-01'
            )

          run
        end

        def get_refund_details(amazon_refund_id)
          operation('GetRefundDetails')
            .add(
              'AmazonRefundId' => amazon_refund_id,
              'Version' => '2013-01-01'
            )

          run
        end

        def valid_signature?(request)

          # Get endpoint
          endpoint = request.original_url

          # Get http parameters
          http_parameters = Rack::Utils.escape(request.env["rack.request.form_vars"])

          # Send request
          operation('VerifySignature')
            .add(
              'UrlEndPoint' => endpoint,
              'HttpParameters' => http_parameters,
              'Version' => '2013-01-01'
            )
          response = run

          # Check for successful response
          status_el = Nokogiri::XML(response.body).css("VerificationStatus").first
          !status_el.nil? && status_el.inner_html == "Success"
        end
      end

      client
    end

  end
end