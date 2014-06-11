class CreateAmazonPaymentsCheckout < ActiveRecord::Migration
  def change
    create_table :spree_amazon_payments_checkouts do |t|
      t.string :order_reference_id
      t.string :authorization_reference_id
      t.string :capture_reference_id
      t.string :refund_reference_id
      t.string :amazon_authorization_id
      t.string :amazon_capture_id
      t.string :amazon_refund_id
      t.integer :payment_id
    end
  end
end
