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

    def purchase(amount, express_checkout, gateway_options={})
      # pp_details_request = provider.build_get_express_checkout_details({
      #   :Token => express_checkout.token
      # })
      # pp_details_response = provider.get_express_checkout_details(pp_details_request)

      # pp_request = provider.build_do_express_checkout_payment({
      #   :DoExpressCheckoutPaymentRequestDetails => {
      #     :PaymentAction => "Sale",
      #     :Token => express_checkout.token,
      #     :PayerID => express_checkout.payer_id,
      #     :PaymentDetails => pp_details_response.get_express_checkout_details_response_details.PaymentDetails
      #   }
      # })

      # pp_response = provider.do_express_checkout_payment(pp_request)
      # if pp_response.success?
      #   # We need to store the transaction id for the future.
      #   # This is mainly so we can use it later on to refund the payment if the user wishes.
      #   transaction_id = pp_response.do_express_checkout_payment_response_details.payment_info.first.transaction_id
      #   express_checkout.update_column(:transaction_id, transaction_id)
      #   # This is rather hackish, required for payment/processing handle_response code.
      #   Class.new do
      #     def success?; true; end
      #     def authorization; nil; end
      #   end.new
      # else
      #   class << pp_response
      #     def to_s
      #       errors.map(&:long_message).join(" ")
      #     end
      #   end
      #   pp_response
      # end
    end

    def refund(payment, amount)
      # refund_type = payment.amount == amount.to_f ? "Full" : "Partial"
      # refund_transaction = provider.build_refund_transaction({
      #   :TransactionID => payment.source.transaction_id,
      #   :RefundType => refund_type,
      #   :Amount => {
      #     :currencyID => payment.currency,
      #     :value => amount },
      #   :RefundSource => "any" })
      # refund_transaction_response = provider.refund_transaction(refund_transaction)
      # if refund_transaction_response.success?
      #   payment.source.update_attributes({
      #     :refunded_at => Time.now,
      #     :refund_transaction_id => refund_transaction_response.RefundTransactionID,
      #     :state => "refunded",
      #     :refund_type => refund_type
      #   }, :without_protection => true)
      # end
      # refund_transaction_response
    end
  end
end