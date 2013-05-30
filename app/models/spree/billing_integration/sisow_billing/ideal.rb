module Spree
  class BillingIntegration::SisowBilling::Ideal < BillingIntegration

    def payment_profiles_supported?
      false
    end

    def redirect_url(order, opts = {})
      sisow = BillingIntegration::SisowBilling.new(order)
      sisow.start_transaction('ideal', opts)
    end

    def self.issuer_list
      BillingIntegration::SisowBilling.configure
      Sisow::Issuer.list
    end
  end 
end
