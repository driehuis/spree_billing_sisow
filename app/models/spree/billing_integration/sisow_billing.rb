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
        @sisow_transaction.update_attributes(status : @callback.status, sha1 : @callback.sha1)


        @payment = @order.payments.where(amount : @order.total, source_id : @sisow_transaction, payment_method_id : payment_method).first
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
        config.merchant_id = Spree::Config.sisow_merchant_id
        config.merchant_key = Spree::Config.sisow_merchant_key
        config.test_mode = Spree::Config.sisow_test_mode
        config.debug_mode = Spree::Config.sisow_debug_mode
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
