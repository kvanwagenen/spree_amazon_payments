class Spree::Admin::AmazonPaymentsSettingsController < Spree::Admin::BaseController
  helper 'spree/admin/amazon_payments'
  
  def update
    params.each do |name, value|
      next unless Spree::AmazonPayments::Config.has_preference? name
      Spree::AmazonPayments::Config[name] = value
    end
    
    respond_to do |format|
      format.html {
        redirect_to admin_amazon_payments_settings_path
      }
    end
  end

end
