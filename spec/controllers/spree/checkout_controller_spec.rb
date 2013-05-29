require 'spec_helper'

describe Spree::CheckoutController do
  let(:token) { 'some_token' }
  let(:user) { stub_model(Spree::LegacyUser) }
  let(:order) { FactoryGirl.create(:order_with_totals) }

  before do
    controller.stub :try_spree_current_user => user
    controller.stub :current_order => order
  end

  #it "should handle the sisow success response and set the flash to thank_you_for_your_order" do
  #
  #end
  #
  #it "should handle the sisow cancel response and set the flash to payment_has_been_cancelled" do
  #
  #end
  #
  #it "should handle a garbage sisow response and set the flash to payment_processing_failed" do
  #
  #end

end