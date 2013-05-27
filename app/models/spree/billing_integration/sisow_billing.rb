module Spree
  class BillingIntegration::SisowBilling < BillingIntegration

    def initialize(order, sisow_return_data)
      @order = order
      @callback = Sisow::Api::Callback.new(
          :transaction_id => sisow_return_data[:trxid],
          :entrance_code => sisow_return_data[:ec],
          :status => sisow_return_data[:status],
          :sha1 => sisow_return_data[:sha1]
      )
      @sisow_transaction = SisowTransaction.where(transaction_id: sisow_return_data[:trxid], entrance_code: sisow_return_data[:ec]).first
    end

    def success?
      @payment.completed?
    end

    def failed?
      @payment.failed?
    end

    def cancelled?
      @payment.void?
    end

    def process_response
      if @order.payments.where(:source_type => 'Spree::SisowTransaction').present?
        @callback.validate!

        #Update the transaction with the callback details
        @sisow_transaction.update_attributes(status: @callback.status, sha1: @callback.sha1)


        @payment = @order.payments.where(amount: @order.total, source_id: @sisow_transaction, payment_method_id: payment_method).first
        @payment.started_processing!

        if @callback.valid?
          if @callback.success?
            complete_payment
          elsif callback.failure? OR callback.expired?
            fail_payment
          elsif callback.cancelled?
            cancel_payment
          end
        end
      end
    end

    def self.configure_sisow
      Sisow.configure do |config|
        config.merchant_id = '2537407799'
        config.merchant_key = '0f9b49d384b4836c543f76d23a923e2cd2cfaec6'
        config.test_mode = true
        config.debug_mode = true
      end
    end

    def self.start_transaction(order, opts = {}, transaction_type = "ideal")
      sisow_transaction = SisowTransaction.create(transaction_type: transaction_type,
          transaction_id: nil,
          entrance_code: nil,
          status: 'pending',
          sha1: nil)

      payment_method = PaymentMethod.where(type: "Spree::BillingIntegration::SisowBilling::#{transaction_type.capitalize}").first
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

      #Configure and initialize the provider
      self.configure_sisow
      sisow = self.provider(transaction_type, opts)

      #Update the transaction id and entrance code on the sisow transaction
      sisow_transaction.update_attributes(transaction_id: sisow.transaction_id, entrance_code: payment.identifier)

      sisow.payment_url
    end

    def self.provider(transaction_type, options)
      case transaction_type
        when 'ideal'
          return Sisow::IdealPayment.new(options)
        when 'bancontact'
          return Sisow::BancontactPayment.new(options)
        when 'sofort'
          return Sisow::SofortPayment.new(options)
        else
          raise "Unknown payment method (#{transaction_type})"
      end
    end

    private
    def payment_method
      case @sisow_transaction.transaction_type
        when 'ideal'
          return PaymentMethod.where(type: "Spree::BillingIntegration::SisowBilling::Ideal").first
        when 'bancontact'
          return PaymentMethod.where(type: "Spree::BillingIntegration::SisowBilling::Bancontact").first
        when 'sofort'
          return PaymentMethod.where(type: "Spree::BillingIntegration::SisowBilling::Sofort").first
        else
          raise "Unknown payment method (#{@sisow_transaction.transaction_type})"
      end
    end

    def complete_payment
      @payment.complete!

      @order.update_attributes({:state => "complete", :completed_at => Time.now}, :without_protection => true)
      @order.finalize!
    end

    def cancel_payment
      @payment.pend!
      @payment.void!
    end

    def fail_payment
      @payment.failure!
    end
  end
end
