# == Schema Information
#
# Table name: friendships
#
#  id                :integer          not null, primary key
#  user_id           :integer          not null
#  friend_id         :integer          not null
#  user_twitter_id   :integer          not null
#  friend_twitter_id :integer          not null
#  is_active         :boolean          default(TRUE)
#  first_active_at   :datetime
#  last_active_at    :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'spec_helper'

describe Friendship do
end
