# == Schema Information
# Schema version: 20121119211120
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
# Indexes
#
#  index_tokens_on_subscriber_id  (subscriber_id)
#  index_tokens_on_twitter_id     (twitter_id)
#

require 'spec_helper'

describe Token do
end
