module Spree
  CheckoutController.class_eval do
    before_filter :confirm_sisow, :only => [:update]

    def sisow_return
      handle_sisow_response
      @order.next
      if @order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        redirect_to order_path(@order, :token => @order.token)
      else
        redirect_to checkout_state_path(@order.state)
      end
    end

    def sisow_cancel
      handle_sisow_response
      redirect_to checkout_state_path(@order.state)
    end

    private
    def handle_sisow_response
      sisow = BillingIntegration::SisowBilling.new(@order)
      sisow.process_response(params)

      if sisow.cancelled?
        flash.alert = Spree.t(:payment_has_been_cancelled)
      end
    end

    def confirm_sisow
      failuretext = '
Door een probleem bij onze bank zijn tijdelijk geen online betalingen mogelijk.<br>
U kunt de betaling opnieuw proberen, of kiezen voor levering op Factuur.
Vermeld dan bij Verzendinstructies s.v.p. dat u problemen ondervond met
de electronische betaling.
Mede namens de bank bieden wij u onze welgemeende excuses aan.
<br>
<a href="/cart">Klik hier om verder te gaan</a>.
      '
      return unless (params[:state] == "payment") && params[:order][:payments_attributes]

      payment_method = PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
      opts = {}
      opts[:return_url] = sisow_return_order_checkout_url(@order)
      opts[:cancel_url] = sisow_cancel_order_checkout_url(@order)
      opts[:notify_url] = sisow_status_update_url(@order)
      opts[:callback_url] = sisow_status_update_url(@order)

      begin
        if payment_method.kind_of?(BillingIntegration::SisowBilling::Ideal)
          opts[:issuer_id] = params[:issuer_id]
          redirect_to payment_method.redirect_url(@order, opts)
        elsif payment_method.kind_of?(BillingIntegration::SisowBilling::Sofort)
          redirect_to payment_method.redirect_url(@order, opts)
        elsif payment_method.kind_of?(BillingIntegration::SisowBilling::Bancontact)
          redirect_to payment_method.redirect_url(@order, opts)
        end
      rescue Sisow::Exception => e
        logger.error "ERROR: Sisow reply failed, #{e.message}"
        render :text => failuretext, :status => 500
      end
    end

  end
end
