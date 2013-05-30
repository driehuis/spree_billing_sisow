module Spree
  class BillingIntegration::SisowBilling::Bancontact < BillingIntegration
    def payment_profiles_supported?
      false
    end

    def redirect_url(order, opts = {})
      sisow = BillingIntegration::SisowBilling.new(order)
      sisow.start_transaction('bancontact', opts)
    end
  end
end
