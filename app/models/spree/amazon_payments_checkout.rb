module Spree
  class AmazonPaymentsCheckout < ActiveRecord::Base

    belongs_to :payment, class_name: "Spree::Payment"

    attr_accessible(
      :order_reference_id, 
      :authorization_reference_id, 
      :capture_reference_id, 
      :refund_reference_id, 
      :amazon_authorization_id,
      :amazon_capture_id,
      :amazon_refund_id
    )

    def actions
      %w{capture void credit}
    end

    def can_capture?(payment)

      return false if payment.state == "completed" || payment.state == "void"

      # Verify authorization status
      response = off_amazon_payments_client.get_authorization_details(amazon_authorization_id)
      xml = Nokogiri::XML(response.body)
      state_el = xml.css("State").first
      !state_el.nil? && state_el.inner_html == "Open"
    end

    def can_void?(payment)
      payment.state != "completed"
    end

    def can_credit?(payment)
      payment.state == "completed" && (payment.order.payment_state == "credit_owed" || payment.order.state == "cancelled")
    end

    private

    def off_amazon_payments_client
      SpreeAmazonPayments::OffAmazonPayments.client
    end
  end
end