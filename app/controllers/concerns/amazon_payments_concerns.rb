require 'active_support/concern'

module Spree
  module AmazonPaymentsConcerns
    extend ActiveSupport::Concern

    def amazon_payments
      # TODO make work with more than one payment method
      Spree::PaymentMethod.find_by_type("Spree::Gateway::AmazonPayments")
    end

  end
end