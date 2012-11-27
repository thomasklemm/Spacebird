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

class UserHistory < ActiveRecord::Base
  belongs_to :user

  # Default hashes
  after_initialize :init

  # Set the default hashes after initialization
  def init
    self.followers ||= {} if self.has_attribute? :followers
    self.friends   ||= {} if self.has_attribute? :friends
    self.statuses  ||= {} if self.has_attribute? :statuses
  end

  ##
  # Serialization
  serialize :followers
  serialize :friends
  serialize :statuses

  def followers_at_day(day); followers[day]; end
  def friends_at_day(day);   friends[day];   end
  def statuses_at_day(day);  statuses[day];  end

  ##
  # Getters for plotting evolution
  def followers_history; counter_per_day(:followers); end
  def friends_history;   counter_per_day(:friends);   end
  def statuses_history;  counter_per_day(:statuses);  end

  def counter_per_day(type)
    daily = []

    # Relevant date range to display
    start_date = history_date_minimum(type)
    end_date = Date.current
    date_range = start_date..end_date

    # Iterate over date range and retrieve historical counter value for each day
    date_range.each do |day|
      daily << [day, counter_at_specific_day(type, day, start_date)]
    end

    # Return array with every day in date range plus respective counter value as array of arrays
    daily
  end

  # Miniumum date in keys array
  def history_date_minimum(type)
    # History as far back as first history was created
    self.send(type).keys.min || user.created_at.to_date
  end

  # Counter values at specific days
  # recursive lookup and displaying if
  def counter_at_specific_day(type, day, start_date)
    count = self.send("#{ type }_at_day", day)

    if count.present?
      return count
    elsif day <= start_date
      # Exit if day less than or equal to start date
      return 0
    else
      counter_at_specific_day(type, day - 1.day, start_date)
    end
  end

  attr_accessible :followers, :friends, :statuses
end
