require 'httparty'
require 'net/https'
require 'json'
require 'uri'

module Spree
  class AmazonController < Devise::SessionsController
    def login
      
      # Validate access token
      response = HTTParty.get("https://api.amazon.com/auth/o2/tokeninfo?access_token=#{Rack::Utils.escape(params[:access_token])}")
      
      # Request profile from amazon
      profile_uri = Spree::AmazonPayments::Config[:profile_api_endpoint]
      profile = HTTParty.get("#{profile_uri}?access_token=#{Rack::Utils.escape(params[:access_token])}")

      # Lookup or create user
      user = User.find_by_email(profile["email"]) || User.create(email: profile["email"])
      
      # Set the user's password to be their amazon profile id if we are creating new from an amazon profile
      if user.password.nil?
        user.password = profile["user_id"]
        user.save!
      end

      # Update access token for user
      session[:auth_source] = "amazon"

      # Login user
      sign_in user, :bypass => true

      redirect_back_or_default(after_sign_in_path_for(user))
    end

    def payment_success
      # See 
    end

    def payment_cancel
      flash[:notice] = Spree.t('flash.cancel', :scope => 'amazon_payments')
      order = current_order || raise(ActiveRecord::RecordNotFound)
      redirect_to checkout_state_path(order.state)
    end

    private 

    def redirect_back_or_default(default)
      redirect_to(session["spree_user_return_to"] || default)
      session["spree_user_return_to"] = nil
    end
    
  end
end