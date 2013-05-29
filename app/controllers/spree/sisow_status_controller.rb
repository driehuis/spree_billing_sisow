module Spree
  class SisowStatusController < ApplicationController
    def update
      @order = Order.find_by_number!(params[:order_id])
      sisow = BillingIntegration::SisowBilling.new(@order)
      sisow.process_response(params)
      render :text => ""
    end

  end
end
