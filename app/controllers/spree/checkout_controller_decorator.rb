module Spree
  CheckoutController.class_eval do
    before_filter :confirm_sisow, :only => [:update]

    def sisow_return
      handle_sisow_response
      redirect_to completion_route
    end

    def sisow_cancel
      handle_sisow_response
      redirect_to edit_order_path(@order)
    end

    private
    def handle_sisow_response
      sisow = BillingIntegration::SisowBilling.new(@order, params)
      sisow.process_response

      if sisow.success?
        flash.notice = Spree.t(:thank_you_for_your_order)
      elsif sisow.cancelled?
        flash.warning = Spree.t(:payment_has_been_cancelled)
      elsif sisow.failed?
        flash.error = Spree.t(:payment_processing_failed)
      end
    end

    def confirm_sisow
      return unless (params[:state] == "payment") && params[:order][:payments_attributes]

      payment_method = PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
      opts = {}
      opts[:return_url] = sisow_return_order_checkout_url(@order)
      opts[:cancel_url] = sisow_cancel_order_checkout_url(@order)
      opts[:notify_url] = sisow_status_update_path

      if payment_method.kind_of?(BillingIntegration::SisowBilling::Ideal)
        opts[:issuer_id] = params[:issuer_id]
        redirect_to payment_method.redirect_url(@order, opts)
      elsif payment_method.kind_of?(BillingIntegration::SisowBilling::Sofort)
        redirect_to payment_method.redirect_url(@order, opts)
      elsif payment_method.kind_of?(BillingIntegration::SisowBilling::Bancontact)
        redirect_to payment_method.redirect_url(@order, opts)
      else
        flash.error = Spree.t(:payment_processing_failed)
        redirect_to completion_route
      end
    end

  end
end
