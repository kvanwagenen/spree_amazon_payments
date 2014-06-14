require 'spree_core'

module Spree
  module AmazonPayments
    def self.config(&block)
      
    end
  end
end

require 'spree_amazon_payments/engine'
require 'spree_amazon_payments/amazon_payments_exceptions'