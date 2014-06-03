module Spree
  class AmazonCheckoutController < CheckoutController

    # Filters
    # skip_before_filter :load_order_with_lock
    # before_filter :load_order
    layout 'spree/layouts/checkout'

    def update

      case params[:state]

      when "address"

        # Address has been selected. Move to delivery.
        off_amazon_payments_client = SpreeAmazonPayments::OffAmazonPayments.client
        order_reference_details = off_amazon_payments_client.get_order_reference_details(params[:amazon_order_reference_id])
        xml = Nokogiri::XML(order_reference_details.body)
        state_abbr = xml.css("StateOrRegion").first.inner_html
        zip = xml.css("PostalCode").first.inner_html
        country_code = xml.css("CountryCode").first.inner_html

        # Check for any existing partial addresses and purge them
        @order.user.purge_incomplete_addresses

        # Create partial shipping address
        ship_address = Address.new(zipcode: zip)
        ship_address.state = State.find_by_abbr(state_abbr)
        ship_address.country = Country.find_by_iso(country_code)
        ship_address.save!(:validate => false)
        @order.ship_address = ship_address

        # Move to delivery state
        @order.create_tax_charge!
        @order.create_proposed_shipments
        @order.instance_eval do 
          ensure_available_shipping_rates
        end
        @order.state = "delivery"
        @order.save!(:validate => false)

        redirect_to(amazon_checkout_state_path('delivery'))

      when "payment"

        # Payment has been selected. Move to confirm.
        @order.state = "confirm"
        @order.save!(:validate => false)

        redirect_to(amazon_checkout_state_path('confirm'))

      when "confirm"
        # Order confirmed. Begin transation process with amazon payments

      else

      end

    end

    def show
      state = params[:state] || "address"
      render :file => "spree/amazon_payments/checkout_#{state}"
    end

    private

    def load_order_with_lock
      @order = current_order(lock: true)
      redirect_to spree.cart_path and return unless @order
    end

    # Overridden before_filter from CheckoutController
    def ensure_valid_state

    end
  end
end