module Spree
  class BillingIntegration::SisowBilling::Sofort < BillingIntegration
    include Rails.application.routes.url_helpers
    preference :test_mode, :boolean, :default => false
    preference :debug_mode, :boolean, :default => false
    preference :merchant_id, :string
    preference :merchant_key, :string
    preference :language, :string, :default => 'NL'
    preference :payment_options, :string, :default => 'ACC'

    attr_accessible :preferred_merchant_id, :preferred_merchant_key, :preferred_language, :preferred_test_mode,
                    :preferred_debug_mode, :preferred_server, :preferred_payment_options

    def payment_profiles_supported?
      false
    end

    def redirect_url(order, opts = {})
      sisow_transaction = SisowTransaction.create(transaction_type: 'sofort',
          transaction_id: sisow.transaction_id,
          entrance_code: nil,
          status: 'pending',
          sha1: nil)
      payment_method = PaymentMethod.where(type: "Spree::BillingIntegration::SisowBilling::Sofort").first
      payment = order.payments.create({:amount => order.total,
                                       :source => sisow_transaction,
                                       :payment_method => payment_method},
                                      :without_protection => true)

      #Update the entrance code with the payment identifier
      sisow_transaction.update_attributes(entrance_code: payment.identifier)

      #Update the payment state
      payment.started_processing!
      payment.pend!

      #Set the options needed for the Sisow payment url
      opts[:description] = "#{Spree::Config.site_name} - Order: #{order.number}"
      opts[:purchase_id] = order.number
      opts[:amount] = (order.total * 100).to_i
      opts[:entrance_code] = payment.identifier
      @options = opts

      sisow = self.provider
      sisow.payment_url
    end

    def provider
      Spree::BillingIntegration::SisowBilling.configure_sisow
      Sisow::SofortPayment.new(options)
    end

    private
    def options
      @options
    end

  end
end
