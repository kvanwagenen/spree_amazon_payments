require 'ostruct'
require 'nokogiri'

module Spree
  class Gateway::AmazonPayments < Gateway
    preference :seller_id, :string, :default => ''
    preference :client_id, :string, :default => ''
    preference :client_secret, :string, :default => ''
    preference :amazon_mws_endpoint, :string, :default => ''
    preference :widgets_js_url, :string, :default => ''
    preference :profile_api_endpoint, :string, :default => ''
    preference :marketplace_id, :string, :default => ''
    preference :aws_access_key_id, :string, :default => ''
    preference :aws_secret_access_key, :string, :default => ''

    attr_accessible :preferred_seller_id, :preferred_client_id, :preferred_client_secret,
                    :preferred_amazon_mws_endpoint, :preferred_widgets_js_url, :preferred_profile_api_endpoint,
                    :preferred_marketplace_id, :preferred_aws_access_key_id, :preferred_aws_secret_access_key

    def supports?(source)
      true
    end

    def provider_class
      ::SpreeAmazonPayments::OffAmazonPayments
    end

    def provider
      provider_class.new
    end

    def auto_capture?
      false
    end

    def method_type
      'amazon_payments'
    end

    def payment_profiles_supported?
      true
    end

    def authorize(amount, amazon_payments_checkout, gateway_options)
      payment = amazon_payments_checkout.payment
      order = payment.order

      # Verify there are no existing authorizations that will conflict
      checkouts = Spree::AmazonPaymentsCheckout.where("authorization_reference_id LIKE '#{order.number}%'").scoped
      if checkouts.length > 1

        # An existing authorization has already been processed. Prevent second attempt from continuing.
        raise SpreeAmazonPayments::TransactionAmountExceededException
      end
      # checkouts.each do |checkout|
      #   if !checkout.amazon_authorization_id.nil?

      #     # Ensure the authorization status is open
      #     xml = Nokogiri::XML(off_amazon_payments_client.get_authorization_details(checkout.amazon_authorization_id).body)
      #     state_el = xml.css("State").first
      #     if !state_el.nil? && (state_el.inner_html == "Open" || state_el.inner_html == "Pending")

      #       # An existing authorization has already been processed. Prevent second attempt from continuing.
      #       raise SpreeAmazonPayments::TransactionAmountExceededException
      #     end
      #   end
      # end

      # Request authorization
      begin
        response = off_amazon_payments_client.authorize(
          amazon_payments_checkout.order_reference_id, 
          amazon_payments_checkout.authorization_reference_id, 
          amount, 
          gateway_options[:currency]
        )

        # Read and save amazon authorization id
        xml = Nokogiri::XML(response.body)
        auth_id = xml.css("AmazonAuthorizationId").first.inner_html
        auth_status = xml.css("AuthorizationStatus State").first.inner_html
        reason_code_el = xml.css("AuthorizationStatus ReasonCode").first
        amazon_payments_checkout.amazon_authorization_id = auth_id
        amazon_payments_checkout.save!

        # Raise exceptions for any authorization errors
        if auth_status == "Declined"

          # Destroy checkout instance
          amazon_payments_checkout.destroy
          
          # Handle reason code
          if !reason_code_el.nil?
            reason_code = reason_code_el.inner_html
            case reason_code
            when "InvalidPaymentMethod"
              raise SpreeAmazonPayments::InvalidPaymentMethodException
            when "AmazonRejected"
              raise SpreeAmazonPayments::AmazonRejectedAuthorizationException
            when "ProcessingFailure"
              raise SpreeAmazonPayments::ProcessingFailureException
            when "TransactionTimedOut"
              raise SpreeAmazonPayments::TransactionTimedOutException
            end
          end
        end
        
        # Create response for processing module
        response = OpenStruct.new({
          :success? => (auth_status == "Open"),
          :authorization => auth_id,
          :avs_result => {'code' => nil},
          :cvv_result => false
        })
        return response

      rescue Excon::Errors::BadRequest => e
        logger.error("Attempted to authorize amazon payment more than once. #{self.to_s}:id(#{self.id})")
        return OpenStruct.new({:success? => false})
      end
    end

    def capture(payment, amazon_payments_checkout, gateway_options)
      
      # Verify authorization status
      if amazon_payments_checkout.can_capture?(payment)
        
        # Capture payment
        begin
          capture_reference_id = "#{payment.order.number}_cap"
          response = off_amazon_payments_client.capture(
            amazon_payments_checkout.amazon_authorization_id,
            capture_reference_id, 
            payment.money.money.to_f,
            gateway_options[:currency]
          )

          # Save capture info
          xml = Nokogiri::XML(response.body)
          state = xml.css("CaptureStatus State").first.inner_html          
          amazon_capture_id = xml.css("AmazonCaptureId").first.inner_html          
          amazon_payments_checkout.capture_reference_id = capture_reference_id
          amazon_payments_checkout.amazon_capture_id = amazon_capture_id
          amazon_payments_checkout.save!
          
          if state == "Declined"

            # Raise exceptions for any capture errors
            reason_code_el = xml.css("CaptureStatus ReasonCode").first
            if !reason_code_el.nil?
              reason_code = reason_code_el.inner_html
              case reason_code
              when "AmazonRejected"
                raise SpreeAmazonPayments::AmazonRejectedCaptureException
              when "ProcessingFailure"
                raise SpreeAmazonPayments::ProcessingFailureException
              end
            end
          end

        rescue Excon::Errors::BadRequest => e
          response = OpenStruct.new({
            :success? => false,
            :to_s => ""
          })
          response.instance_eval do
            def to_s
              "Error requesting capture on payment"
            end
          end
          return response
        end

        # Create response for processing module
        OpenStruct.new({:success? => true})
      else
        response = OpenStruct.new({
          :success? => false,
          :to_s => ""
        })
        response.instance_eval do
          def to_s
            "Payment authorization has been declined"
          end
        end
        response
      end
    end

    def void(authorization_code, amazon_payments_checkout, gateway_options)
      begin
        response = off_amazon_payments_client.cancel_order_reference(
          amazon_payments_checkout.order_reference_id
        )
        OpenStruct.new({:success? => true})
      rescue
        logger.error("Failed to void amazon payment. Checkout id:(#{amazon_payments_checkout.id}")
        return OpenStruct.new({
          :success? => false,
          :to_s => "Error voiding payment"
        })
      end
    end

    def credit(credit_cents, amazon_payments_checkout, amazon_authorization_id, gateway_options)
      begin
        credit_amount = (credit_cents * 0.01).round(2)

        # If told to credit 0, credit the full amount instead
        if credit_amount == 0
          credit_amount = amazon_payments_checkout.payment.amount.to_f
          credit_cents = (credit_amount * 100).to_i
        end
        
        refund_reference_id = "#{amazon_payments_checkout.payment.order.number}_refund"
        response = off_amazon_payments_client.refund(
          amazon_payments_checkout.amazon_capture_id,
          refund_reference_id,
          credit_amount,
          gateway_options[:currency]
        )

        # Save refund id
        xml = Nokogiri::XML(response.body)
        refund_id = xml.css("AmazonRefundId").first.inner_html
        state = xml.css("RefundStatus State").first.inner_html
        reason_code_el = xml.css("RefundStatus ReasonCode").first
        amazon_payments_checkout.refund_reference_id = refund_reference_id
        amazon_payments_checkout.amazon_refund_id = refund_id
        amazon_payments_checkout.save!

        # Raise exceptions for any refund errors
        if state == "Declined"
          if !reason_code_el.nil?
            reason_code = reason_code_el.inner_html
            case reason_code
            when "AmazonRejected"
              raise SpreeAmazonPayments::AmazonRejectedRefundException
            when "ProcessingFailure"
              raise SpreeAmazonPayments::ProcessingFailureException
            end
          end
        end

      rescue Excon::Errors::BadRequest => e
        logger.error("#{e.to_s}\n#{e.backtrace.join('\n')}")
        response = OpenStruct.new({
          :success? => false
        })
        response.instance_eval do
          def to_s
            "Error requesting credit on payment"
          end
        end
        return response
      end

      OpenStruct.new({:success? => true})
    end

    def has_authorization?(payment)
      return !payment.source.amazon_authorization_id.nil?
    end

    def has_capture?(payment)
      return !payment.source.amazon_capture_id.nil?
    end

    def has_refund?(payment)
      return !payment.source.amazon_refund_id.nil?
    end

    def order_details_xml(payment)
      off_amazon_payments_client.get_order_reference_details(payment.source.order_reference_id).body
    end

    def authorization_details_xml(payment)
      off_amazon_payments_client.get_authorization_details(payment.source.amazon_authorization_id).body
    end

    def capture_details_xml(payment)
      off_amazon_payments_client.get_capture_details(payment.source.amazon_capture_id).body
    end

    def refund_details_xml(payment)
      off_amazon_payments_client.get_refund_details(payment.source.amazon_refund_id).body
    end

    private

    def off_amazon_payments_client
      SpreeAmazonPayments::OffAmazonPayments.client
    end
  end
end