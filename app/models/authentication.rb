class Authentication < ActiveRecord::Base
  belongs_to :subscriber
  attr_accessible :provider, :uid
end
