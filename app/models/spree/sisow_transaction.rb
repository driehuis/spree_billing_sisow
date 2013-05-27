module Spree
  class SisowTransaction < ActiveRecord::Base
    has_many :payments, :as => :source
    attr_accessible :transaction_id, :transaction_type, :entrance_code, :status, :sha1
    
    def actions
      []
    end
  end
end
