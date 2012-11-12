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
#  canceled_at       :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Friendship < ActiveRecord::Base
  ##
  # Associations
  belongs_to  :user,
              # Set to false and column on user renamed
              counter_cache: false

  belongs_to  :friend,
              class_name: 'User',
              counter_cache: false

  ##
  # Field defaults
  def is_active
    self[:is_active] || true
  end

  ##
  # Callbacks
  #
  # Add twitter ids to friendship
  before_create :assign_twitter_ids
  def assign_twitter_ids
    self[:user_twitter_id]   = User.find(user_id).twitter_id
    self[:friend_twitter_id] = User.find(friend_id).twitter_id
  end

  # Mass-assignment
  attr_accessible :user_id, :friend_id, :user_twitter_id, :friend_twitter_id
end
