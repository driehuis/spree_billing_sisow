require 'spec_helper'

describe Spree::CheckoutController do
  let(:token) { 'some_token' }
  let(:user) { stub_model(Spree::LegacyUser) }
  let(:order) { FactoryGirl.create(:order_with_totals) }
  let(:sisow_billing) { mock_model(Spree::BillingIntegration::SisowBilling) }

  before do
    controller.stub :try_spree_current_user => user
    controller.stub :current_order => order
  end

  #it "should handle the sisow success response and set the flash to thank_you_for_your_order" do
  #  Spree::BillingIntegration::SisowBilling.stub(:new).and_return(sisow_billing)
  #  sisow_billing.stub(:process_response)
  #  sisow_billing.stub(:failed?).and_return(false)
  #  sisow_billing.should_receive(:succes?).and_return(true)
  #  spree_post :sisow_return
  #
  #  expect(flash[:notice]).to be_false
  #end
  #
  #it "should handle the sisow cancel response and set the flash to payment_has_been_cancelled" do
  #
  #end
  #
  #it "should handle a garbage sisow response and set the flash to payment_processing_failed" do
  #  Spree::BillingIntegration::SisowBilling.stub(:new).and_raise("this error")
  #  #.and_return(sisow_billing)
  #  sisow_billing.stub(:process_response).and_raise("this error")
  #  sisow_billing.should_receive(:failed?).and_return(false)
  #  spree_post :sisow_return
  #
  #  expect(flash[:notice]).to be_false
  #end

end