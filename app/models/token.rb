class Token < ActiveRecord::Base
  belongs_to :subscriber

  ##
  # Validations
  validates :twitter_id,
            :token,
            :secret,
            presence: true

  attr_accessible :twitter_id, :token, :secret
end
