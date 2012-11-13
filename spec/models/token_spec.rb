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

require 'spec_helper'

describe Token do
  pending "add some examples to (or delete) #{__FILE__}"
end
