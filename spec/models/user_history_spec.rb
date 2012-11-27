# == Schema Information
# Schema version: 20121119211120
#
# Table name: user_histories
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  followers  :text
#  friends    :text
#  statuses   :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_user_histories_on_user_id  (user_id)
#

require 'spec_helper'

describe UserHistory do
end
