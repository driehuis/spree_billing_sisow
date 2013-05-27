module Spree
  class SisowStatusController < ApplicationController
    def update
      @order = Order.find_by_number!(params[:order_id])
      sisow = BillingIntegration::SisowBilling.new(@order, params)
      sisow.process_response
      render :text => ""
    end

  end
end
