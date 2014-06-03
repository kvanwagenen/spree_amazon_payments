module Spree
  class AmazonPaymentCheckout < ActiveRecord::Base
    def actions
      %w{capture void credit}
    end

    def can_capture?(payment)
      
    end

    def can_void?(payment)

    end

    def can_credit?(payment)

    end
  end
end