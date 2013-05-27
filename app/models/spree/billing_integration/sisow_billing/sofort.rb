module Spree
  class BillingIntegration::SisowBilling::Sofort < BillingIntegration
    preference :language, :string, :default => 'not_used'
    preference :payment_options, :string, :default => 'not_used'
    preference :server, :string, :default => 'not_used'

    attr_accessible :preferred_language, :preferred_server, :preferred_payment_options

    def payment_profiles_supported?
      false
    end

    def redirect_url(order, opts = {})
      BillingIntegration::SisowBilling.start_transaction(order, opts, 'sofort')
    end

    private
    def options
      @options
    end

  end
end
