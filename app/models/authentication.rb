# == Schema Information
#
# Table name: authentications
#
#  id            :integer          not null, primary key
#  subscriber_id :integer
#  provider      :string(255)
#  uid           :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Authentication < ActiveRecord::Base
  belongs_to :subscriber

  ##
  # Validations
  validates :provider,
            :uid,
            presence: true

  attr_accessible :provider, :uid
end
