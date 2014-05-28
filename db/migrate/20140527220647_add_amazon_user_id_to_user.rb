class AddAmazonUserIdToUser < ActiveRecord::Migration
  def change
    add_column :spree_users, :amazon_user_id, :string
  end
end
