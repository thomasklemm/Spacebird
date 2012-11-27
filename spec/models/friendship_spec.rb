# == Schema Information
# Schema version: 20121119211120
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
# Indexes
#
#  index_friendships_on_user_id_and_friend_id                  (user_id,friend_id)
#  index_friendships_on_user_twitter_id_and_friend_twitter_id  (user_twitter_id,friend_twitter_id)
#

require 'spec_helper'

describe Friendship do
end
