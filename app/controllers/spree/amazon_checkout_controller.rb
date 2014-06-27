require_dependency 'concerns/amazon_payments_concerns'

module Spree
  class AmazonCheckoutController < CheckoutController
    include AmazonPaymentsConcerns

    @@CONSTRAINTS_KEY_MAP = {
      "ShippingAddressNotSet" => :shipping_address_not_set,
      "PaymentPlanNotSet" => :payment_plan_not_set,
      "AmountNotSet" => :amount_not_set,
      "PaymentMethodNotAllowed" => :payment_method_not_allowed
    }

    # Filters
    before_filter :prevent_browser_caching

    # Debugging
    after_filter :log_response_body, :only => [:update]

    def log_response_body
      $stderr.puts response.body
    end

    layout 'spree/layouts/checkout'

    def prevent_browser_caching
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end

    def update

      case params[:state]

      when "address"

        # Save order reference id to session
        session[:amazon_order_reference_id] = params[:amazon_order_reference_id]

        # Address has been selected. Move to delivery.
        xml = order_reference_details_xml
        state_abbr = xml.css("StateOrRegion").first.inner_html
        zip = xml.css("PostalCode").first.inner_html
        country_code = xml.css("CountryCode").first.inner_html

        # Check for any existing partial addresses and purge them
        @order.bill_address = nil
        @order.ship_address = nil
        @order.save!
        @order.user.purge_incomplete_addresses

        # Create partial shipping address
        ship_address = Address.new(zipcode: zip)
        ship_address.state = State.find_by_abbr(state_abbr)
        ship_address.country = Country.find_by_iso(country_code)
        ship_address.save!(:validate => false)
        @order.user.addresses << ship_address
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

        # Ensure order is open
        xml = order_reference_details_xml
        if xml.css("State").first.inner_html == "Suspended"
          flash[:error] = "Your payment method needs to be updated with Amazon before you can continue."
          redirect_to(amazon_checkout_state_path('payment'))
          return
        end

        # Payment selected by user. Set total on order reference if necessary
        amount_el = xml.css("OrderTotal Amount").first
        if amount_el.nil? || amount_el.inner_html.to_f != @order.total.to_f
          @order.update_totals
          off_amazon_payments_client.set_order_reference_details(session[:amazon_order_reference_id], @order.total.to_f, @order.currency, @order.number)
        end

        # Verify no constraints on order
        xml = order_reference_details_xml
        constraints = xml.css("ConstraintID")
        if constraints.empty?

          # Move to confirm
          @order.state = "confirm"
          @order.save!(:validate => false)

          redirect_to(amazon_checkout_state_path('confirm'))
        else

          # Handle constraints
          handle_constraints constraints
        end

      when "confirm"

        logger.error("Confirming amazon payment order. Order: #{@order.id}:#{@order.to_s} state:#{@order.state}")
        logger.error("Order: #{@order.attributes}")
        logger.error("Order shipments: #{@order.shipments}")
        logger.error("Order payments: #{@order.payments}")
        sources = @order.payments.map{|o|o.source}
        logger.error("Order sources: #{sources}")
        logger.error("Order adjustments: #{@order.adjustments}")

        # Prevent unwanted reauthorizations
        if !@order.nil?
          if @order.completed?
            finalize_order_and_redirect
            return
          elsif @order.payments.any?
            @order.payments.each do |p|
              if p.source.instance_of?(Spree::AmazonPaymentsCheckout) && p.source.can_capture?(p)
                logger.error("SpreeAmazonPayments Warning: Attempted to authorize payment(#{payment.id}) twice.")
                flash[:error] = "Your payment has already been successfully authorized. You won't be charged until it ships."

                # Update the payment
                p.state = "pending"
                p.save!

                # Update the order
                @order.state = "complete"
                @order.payment_total = p.amount
                @order.shipment_state = "pending"
                @order.payment_state = "balance_due"
                @order.save!

                finalize_order_and_redirect
                return
              end
            end  
          end
        end

        # Order confirmed by user. Confirm order reference
        off_amazon_payments_client.confirm_order_reference(session[:amazon_order_reference_id])

        # Get order details after confirm to update shipping address and user information
        xml = order_reference_details_xml
        phone = xml.css("Phone").first.inner_html
        name = xml.css("Buyer Name").first.inner_html
        address_1 = xml.css("AddressLine1").first.inner_html
        address_2 = nil
        if xml.css("AddressLine2").any?
          address_2 = xml.css("AddressLine2").first.inner_html
        end
        if xml.css("AddressLine3").any?
          address_2 = "#{address_2} #{xml.css("AddressLine3").first.inner_html}"
        end
        city = xml.css("City").first.inner_html
        name_parts = name.split(' ')
        last_name = name_parts[-1]
        first_name = name_parts[0..-2].join(' ')

        # Look for and detach duplicate user addresses
        dups = @order.user.addresses.where(firstname: first_name, lastname: last_name, city: city, address1: address_1, phone: phone).scoped
        dups.each{|a| a.update_attribute(:user_id, nil)}

        # Update shipping and billing addresses
        @order.ship_address.firstname = first_name
        @order.ship_address.lastname = last_name
        @order.ship_address.address1 = address_1
        @order.ship_address.address2 = address_2
        @order.ship_address.city = city
        @order.ship_address.phone = phone
        @order.ship_address.save!(:validate => false)
        @order.bill_address = @order.ship_address
        @order.save(:validate => false)

        # Create payment with an amazon payments checkout as its source
        auth_number = Spree::AmazonPaymentsCheckout.where("authorization_reference_id LIKE '#{@order.number}%'").count + 1
        amazon_payments_checkout = Spree::AmazonPaymentsCheckout.new({
          :order_reference_id => session[:amazon_order_reference_id],
          :authorization_reference_id => "#{@order.number}_auth_#{auth_number}"
        }, :without_protection => true)
        payment = @order.payments.create({
          :source => amazon_payments_checkout,
          :amount => @order.total,
          :payment_method => amazon_payments
        }, :without_protection => true)
        amazon_payments_checkout.payment = payment
        amazon_payments_checkout.save!

        begin

          # Move order to next state by hand
          @order.process_payments! if @order.payment_required?
          @order.state = "complete"
          @order.finalize!
          @order.save!

          logger.error "Order state after authorize: #{@order.state}"
          logger.error("Order: #{@order.attributes}")
          logger.error("Order shipments: #{@order.shipments}")
          logger.error("Order payments: #{@order.payments}")
          sources = @order.payments.map{|o|o.source}
          logger.error("Order sources: #{sources}")
          logger.error("Order adjustments: #{@order.adjustments}")

        # Handle any authorization exceptions
        rescue SpreeAmazonPayments::InvalidPaymentMethodException
          flash[:error] = "There is a problem with your selected payment method. You need to update your payment method information with Amazon."
          redirect_to(amazon_checkout_state_path('payment'))
          return
        rescue SpreeAmazonPayments::AmazonRejectedAuthorizationException
          flash[:error] = "Amazon rejected the payment."
          redirect_to(amazon_checkout_state_path('payment'))
          return
        rescue SpreeAmazonPayments::ProcessingFailureException
          flash[:error] = "Error processing payment authorization."
          redirect_to(amazon_checkout_state_path('payment'))
          return
        rescue SpreeAmazonPayments::TransactionTimedOutException
          flash[:error] = "Authorization timed out. Select a different payment method or try again later."
          redirect_to(amazon_checkout_state_path('payment'))
          return
        rescue SpreeAmazonPayments::TransactionAmountExceededException
          logger.error("SpreeAmazonPayments Warning: Attempted to authorize payment(#{payment.id}) twice.")
          flash[:error] = "Your payment has already been successfully authorized. You won't be charged until it ships."
        rescue Exception => e
          logger.error e.message + "\n  " + e.backtrace.join("\n  ")
        end

        # Redirect if complete
        if @order.completed?
          finalize_order_and_redirect
        else
          redirect_to amazon_checkout_state_path(@order.state)
        end

      else

      end

    end

    def handle_constraints
      constraints = constraints.map{|e| e.inner_html}
      if constraints.includes?("PaymentPlanNotSet")
        flash[:error] = Spree.t(@@CONSTRAINTS_KEY_MAP["PaymentPlanNotSet"])
        redirect_to(amazon_checkout_state_path('payment'))
      elsif constraints.includes?("ShippingAddressNotSet")
        flash[:error] = Spree.t(@@CONSTRAINTS_KEY_MAP["ShippingAddressNotSet"])
        redirect_to(amazon_checkout_state_path('address'))
      elsif constraints.includes?("AmountNotSet")
        flash[:error] = Spree.t(@@CONSTRAINTS_KEY_MAP["AmountNotSet"])
        redirect_to(amazon_checkout_state_path('payment'))
      elsif constraints.includes?("PaymentMethodNotAllowed")
        flash[:error] = Spree.t(@@CONSTRAINTS_KEY_MAP["PaymentMethodNotAllowed"])
        redirect_to(amazon_checkout_state_path('payment'))
      else
        flash[:error] = Spree.t(:an_unknown_error_occurred)
        redirect_to(cart_path)
      end
    end

    def show
      state = params[:state] || @order.state
      checkout_states = @order.class.checkout_step_names

      if state == "cart"
        redirect_to cart_path
        return
      elsif !checkout_states.include?(:"#{state}")
        state = @order.state
      end

      if checkout_states.include?(:"#{state}") && checkout_states.index(:"#{state}") < checkout_states.index(:"#{@order.state}")
        @order.state = state
        @order.save!
      end
      render :file => "spree/amazon_payments/checkout_#{state}"
    end

    private

    def finalize_order_and_redirect
      session[:order_id] = nil
      flash.notice = Spree.t(:order_processed_successfully)
      flash[:commerce_tracking] = "nothing special"
      redirect_to completion_route
    end

    def load_order_with_lock
      @order = current_order(lock: true)
      redirect_to spree.cart_path and return unless @order
    end

    # Overridden before_filter from CheckoutController
    def ensure_valid_state

    end

    def off_amazon_payments_client
      SpreeAmazonPayments::OffAmazonPayments.client
    end

    def order_reference_details_xml
      details = off_amazon_payments_client.get_order_reference_details(session[:amazon_order_reference_id])
      Nokogiri::XML(details.body)
    end

    # Overridden before_filter from skrill CheckoutController decorator
    # Fixed nil class error
    def confirm_skrill
      return unless (params[:state] == "payment") && params[:order] && params[:order][:payments_attributes]

      payment_method = PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
      if payment_method.kind_of?(BillingIntegration::Skrill::QuickCheckout)
        #TODO confirming payment method
        redirect_to edit_order_checkout_url(@order, :state => 'payment'),
                    :notice => Spree.t(:complete_skrill_checkout)
      end
    end
  end
end