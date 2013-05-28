require 'spec_helper'

describe Spree::BillingIntegration::SisowBilling::Ideal do
  let(:subject) { Spree::BillingIntegration::SisowBilling::Ideal.new }
  let(:order) { double("Spree::Order") }
  let(:sisow_transaction) { double("Spree::SisowTransaction") }
  let(:payment){ double("Spree::Payment") }

  let(:options) {
    {
      return_url: 'http://www.example.com',
      cancel_url: 'http://www.example.com',
      notify_url: 'http://www.example.com',
      issuer_id: 99
    }
  }

  #Webmock request files
  let(:issuer_list_response) { File.new("spec/webmock_files/ideal_issuer_output") }
  let(:sisow_redirect_url) { File.new("spec/webmock_files/ideal_redirect_url_output") }

  it "should return the issuer list from retrieved from Sisow" do
    lambda {
      stub_request(:get, "http://www.sisow.nl/Sisow/iDeal/RestHandler.ashx/DirectoryRequest?merchantid=2537407799&test=true").to_return(issuer_list_response)
      Spree::BillingIntegration::SisowBilling::Ideal.issuer_list.length.should >= 1
    }.should_not raise_error
  end

  it "should return a payment URL to the Sisow API" do
    stub_request(:get, "http://www.sisow.nl/Sisow/iDeal/RestHandler.ashx/TransactionRequest?amount=300&callbackurl=&cancelurl=http://www.example.com&description=Spree%20Demo%20Site%20-%20Order:%20O12345678&entrancecode=R12345678&issuerid=99&merchantid=2537407799&notifyurl=http://www.example.com&payment=ideal&purchaseid=O12345678&returnurl=http://www.example.com&sha1=876b2c3c20b56f34cad4a9108bd42dd16885baeb&shop_id=&test=true").to_return(sisow_redirect_url)
    payment.stub(:identifier) { "R12345678" }
    order.stub(:total) { 3 }
    order.stub(:number) { "O12345678" }
    order.stub_chain(:payments, :create).and_return(payment)

    payment.should_receive(:started_processing!)
    payment.should_receive(:pend!)

    expect(subject.redirect_url(order, options)).to match(/https:\/\/www\.sisow\.nl\/Sisow\/iDeal\/Simulator\.aspx/)
  end
end