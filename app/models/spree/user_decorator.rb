Spree::User.class_eval do
	attr_accessible :amazon_user_id, :addresses

  def purge_incomplete_addresses
    if respond_to?(:addresses)
      addresses.destroy(addresses.where("spree_addresses.firstname IS NULL || spree_addresses.lastname IS NULL").scoped) #.each{|a| a.destroy!}
    end
  end
end