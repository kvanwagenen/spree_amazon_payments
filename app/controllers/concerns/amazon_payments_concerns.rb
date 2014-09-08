require 'active_support/concern'

module Spree
  module AmazonPaymentsConcerns
    extend ActiveSupport::Concern

    def amazon_payments
      # TODO make work with more than one payment method
      Spree::PaymentMethod.find_by_type("Spree::Gateway::AmazonPayments")
    end

    def ensure_payments_enabled
      if !amazon_payments.show_on_frontend?
        redirect_to cart_path
        return
      end
    end

  end
end