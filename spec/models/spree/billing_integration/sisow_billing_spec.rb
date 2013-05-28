require 'spec_helper'

describe Spree::BillingIntegration::SisowBilling do
  let(:order) {
    Spree::Order.new(:bill_address => Spree::Address.new,
                     :ship_address => Spree::Address.new)
  }
  let(:subject) { Spree::BillingIntegration::SisowBilling.new(order) }

  context "when payment is not initialized" do
    it "should respond to .success? with false" do
      expect(subject.success?).to be_false
    end

    it "should respond to .failed? with false" do
      expect(subject.failed?).to be_false
    end

    it "should respond to .cancelled? with false" do
      expect(subject.cancelled?).to be_false
    end
  end

  it "should return the correct payment provider" do
    expect(subject.send(:payment_provider, 'ideal', {})).to be_kind_of(Sisow::IdealPayment)
    expect(subject.send(:payment_provider, 'sofort', {})).to be_kind_of(Sisow::SofortPayment)
    expect(subject.send(:payment_provider, 'bancontact', {})).to be_kind_of(Sisow::BancontactPayment)
  end
end