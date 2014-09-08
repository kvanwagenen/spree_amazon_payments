require 'httparty'
require 'net/https'
require 'json'
require 'uri'

require_dependency 'concerns/amazon_payments_concerns'

module Spree
  class AmazonLoginController < Devise::SessionsController
    include AmazonPaymentsConcerns

    # Filters
    before_filter :ensure_payments_enabled

    def login      

      # Validate access token
      response = HTTParty.get("https://api.amazon.com/auth/o2/tokeninfo?access_token=#{Rack::Utils.escape(params[:access_token])}")
      
      # Request profile from amazon
      profile_uri = amazon_payments.preferred_profile_api_endpoint
      profile = HTTParty.get("#{profile_uri}?access_token=#{Rack::Utils.escape(params[:access_token])}")

      # Check if user isn't logged in
      if spree_current_user.nil?

        # Lookup or create user
        user = User.find_by_amazon_user_id(profile["user_id"])
        if user.nil?
          user = User.create(email: profile["email"], amazon_user_id: profile["user_id"], password: profile["user_id"])
        end

        # Login user
        sign_in user, :bypass => true

      else

        # Update the user's amazon user id
        spree_current_user.amazon_user_id = profile["user_id"]
        spree_current_user.save!
        user = spree_current_user

      end

      # If user logged in from cart page proceed to checkout
      if request.referrer == cart_url || request.referrer == checkout_state_url("payment")
        redirect_to(amazon_checkout_state_path('address'))
      else
        redirect_back_or_default(after_sign_in_path_for(user))
      end
      
    end

    private 

    def redirect_back_or_default(default)
      redirect_to(session["spree_user_return_to"] || default)
      session["spree_user_return_to"] = nil
    end
  end
end