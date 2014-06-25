class AddDeclineReasonCodeToAmazonPaymentsCheckouts < ActiveRecord::Migration
  def change
    add_column :spree_amazon_payments_checkouts, :decline_reason_code, :string
  end
end
