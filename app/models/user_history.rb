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

  attr_accessible :followers, :friends, :statuses
end
