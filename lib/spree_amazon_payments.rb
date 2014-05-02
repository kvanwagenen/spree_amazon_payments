require 'spree_core'

module Spree
  module AmazonPayments
    def self.config(&block)
      yield(Spree::AmazonPayments::Config)
    end
  end
end

require 'spree_amazon_payments/engine'
