class UserHistory < ActiveRecord::Base
  belongs_to :user

  # Defaults on initialize
  def initialize
    @followers = {}
    @friends = {}
    @statuses = {}
  end

  ##
  # Serialization
  # serialize :followers
  # serialize :friends
  # serialize :statuses

  attr_accessible :followers, :friends, :statuses
end
