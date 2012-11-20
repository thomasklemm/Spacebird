# == Schema Information
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

require 'spec_helper'

describe UserHistory do
end
