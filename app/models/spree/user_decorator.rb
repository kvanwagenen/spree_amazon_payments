Spree::User.class_eval do
	attr_accessible :amazon_user_id, :addresses

  def purge_incomplete_addresses
    if respond_to?(:addresses)
      addresses.delete(addresses.where("spree_addresses.lastname IS NULL").scoped)
    end
  end
end