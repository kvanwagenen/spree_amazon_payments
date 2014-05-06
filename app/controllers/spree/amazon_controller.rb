module Spree
  class AmazonController < Spree::StoreController
    def login
      binding.pry

      # Request profile from amazon

      # Check for existing user with same email

      # Lookup or create user

      # Save access token for user

      # Login user 
      # TODO See update_registration in spree_auth_devise
      redirect_to home_path
    end
  end
end