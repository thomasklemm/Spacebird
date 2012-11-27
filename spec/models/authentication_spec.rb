# == Schema Information
# Schema version: 20121119211120
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
# Indexes
#
#  index_authentications_on_subscriber_id  (subscriber_id)
#

require 'spec_helper'

describe Authentication do
end
