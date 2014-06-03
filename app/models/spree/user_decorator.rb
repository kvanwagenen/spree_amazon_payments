Spree::User.class_eval do
	attr_accessible :amazon_user_id, :addresses

  def purge_incomplete_addresses
    if respond_to?(:addresses)
      addresses.where("ISNULL(spree_address.firstname) || ISNULL(spree_address.lastname").scoped.each{|a| a.destroy!}
    end
  end
end