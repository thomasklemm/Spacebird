# == Schema Information
#
# Table name: tokens
#
#  id            :integer          not null, primary key
#  subscriber_id :integer
#  twitter_id    :integer
#  token         :string(255)
#  secret        :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

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
