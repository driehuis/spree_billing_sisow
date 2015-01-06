module Spree
  class BillingIntegration::SisowBilling < BillingIntegration

    def initialize(order)
      @order = order
      BillingIntegration::SisowBilling.configure
    end

    def success?
      return false unless @payment
      (@payment.completed? && @order.completed?)
    end

    def failed?
      return true unless @payment
      @payment.failed?
    end

    def cancelled?
      return false unless @payment
      @payment.void?
    end

    def process_response(response)
      if @order.payments.where(:source_type => 'Spree::SisowTransaction').present?
        initialize_callback(response)

        if @callback.valid?
          #Update the transaction with the callback details
          @sisow_transaction.update_attributes(status: @callback.status, sha1: @callback.sha1)

          @payment = @order.payments.where(amount: @order.total, source_id: @sisow_transaction, payment_method_id: payment_method).first

          if @callback.cancelled? && !@payment.void?
            cancel_payment
          end
        else
          logger.error "ERROR: Sisow response received for order #{@order.id}), not valid:"
          logger.error @callback.inspect
        end
      else
        logger.error "ERROR: Sisow response received for order #{@order.id}) without SisowTransaction"
      end
    end

    def start_transaction(transaction_type, opts = {})
      @sisow_transaction = SisowTransaction.create(transaction_type: transaction_type, status: 'pending')

      @payment = @order.payments.create(amount: @order.total,   									    										source: @sisow_transaction,
      									payment_method: payment_method)

      #Update the entrance code with the payment identifier
      @sisow_transaction.update(entrance_code: @payment.identifier)

      #Set the options needed for the Sisow payment url
      opts[:description] = "#{Spree::Config.site_name} - Order: #{@order.number}"
      opts[:purchase_id] = @order.number
      opts[:amount] = (@order.total * 100).to_i
      opts[:entrance_code] = @payment.identifier

      #Initialize the provider
      sisow = payment_provider(transaction_type, opts)

      #Update the transaction id and entrance code on the sisow transaction
      @sisow_transaction.update_attributes(transaction_id: sisow.transaction_id, entrance_code: @payment.identifier)

      sisow.payment_url
    end

    def self.configure
      Sisow.configure do |config|
        config.merchant_id = Spree::Config.sisow_merchant_id
        config.merchant_key = Spree::Config.sisow_merchant_key
        config.test_mode = Spree::Config.sisow_test_mode
        config.debug_mode = Spree::Config.sisow_debug_mode
      end
      HTTPI.logger = logger
    end

    private
    def payment_provider(transaction_type, options)
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

    def initialize_callback(sisow_return_data)
      @callback = Sisow::Api::Callback.new(
          :transaction_id => sisow_return_data[:trxid],
          :entrance_code => sisow_return_data[:ec],
          :status => sisow_return_data[:status],
          :sha1 => sisow_return_data[:sha1]
      )

      @sisow_transaction = SisowTransaction.where(transaction_id: sisow_return_data[:trxid], entrance_code: sisow_return_data[:ec]).first
    end

    def cancel_payment
      @payment.void!
    end
  end
end
