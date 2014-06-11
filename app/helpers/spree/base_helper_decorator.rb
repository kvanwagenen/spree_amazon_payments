Spree::BaseHelper.module_eval do

  def amazon_payments
    Spree::PaymentMethod.find_by_type("Spree::Gateway::AmazonPayments")
  end
  
end