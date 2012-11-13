class Authentication < ActiveRecord::Base
  belongs_to :subscriber

  ##
  # Validations
  validates :provider,
            :uid,
            presence: true

  attr_accessible :provider, :uid
end
