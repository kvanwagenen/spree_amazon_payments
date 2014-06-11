Spree::CheckoutHelper.module_eval do

  def checkout_state_path(state)
    regular_checkout_path = url_for(:controller => 'checkout', :action => 'edit', :state => state, :only_path => true)
    request.path.include?("amazon") ? amazon_checkout_state_path(state) : regular_checkout_path
  end

end