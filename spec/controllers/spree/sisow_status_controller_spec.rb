require 'spec_helper'

describe Spree::SisowStatusController do
  let(:order) {
    Spree::Order.new(:bill_address => Spree::Address.new,
                     :ship_address => Spree::Address.new)
  }

  let(:billing_integration) {
    double(Spree::BillingIntegration::SisowBilling)
  }

  let(:params) do
    {
        "order_id" => "O12345678",
        "trxid" => "12345",
        "ec" => "54321",
        "status" => "Pending",
        "sha1" => "1234567890"
    }
  end

  it "should update the transaction status" do
    test_params = params.clone
    test_params.delete(:use_route)
    test_params.merge!({"controller" => "spree/sisow_status", "action"=>"update"})
    billing_integration.should_receive(:process_response).with(test_params)

    Spree::Order.stub(:find_by_number!).with("O12345678").and_return(order)
    Spree::BillingIntegration::SisowBilling.stub(:new).and_return(billing_integration)

    spree_post :update, params
  end

  describe "confirming a none-existing order" do
    before do
      Spree::Order.stub(:find_by_number!).with("O12345678").and_raise(ActiveRecord::RecordNotFound)
    end

    it "should log an error" do
      # Somehow in our spree, Logger is not defined on Rails but on ActionController.
      ActionController::Base.logger.should_receive(:error).with(/ERROR:.*\(O12345678\) not found/)
      spree_post :update, params
    end

    it "should return HTTP status code 500" do
      spree_post :update, params
      response.status.should eq 500
    end
  end
end
