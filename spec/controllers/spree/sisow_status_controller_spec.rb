require 'spec_helper'

describe Spree::SisowStatusController do
  let(:order) {
    Spree::Order.new(:bill_address => Spree::Address.new,
                     :ship_address => Spree::Address.new)
  }

  let(:billing_integration) {
    double(Spree::BillingIntegration::SisowBilling)
  }

  it "should update the transaction status" do
    params = {
        "order_id" => "O12345678",
        "trxid" => "12345",
        "ec" => "54321",
        "status" => "Pending",
        "sha1" => "1234567890"
    }

    test_params = params.clone
    test_params.delete(:use_route)
    test_params.merge!({"controller" => "spree/sisow_status", "action"=>"update"})
    billing_integration.should_receive(:process_response).with(test_params)

    Spree::Order.stub(:find_by_number!).with("O12345678").and_return(order)
    Spree::BillingIntegration::SisowBilling.stub(:new).and_return(billing_integration)

    spree_post :update, params
  end
end