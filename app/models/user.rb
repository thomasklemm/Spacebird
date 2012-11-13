# == Schema Information
#
# Table name: users
#
#  id                               :integer          not null, primary key
#  twitter_id                       :integer          not null
#  screen_name                      :string(255)
#  friends_counter                  :integer          default(0)
#  followers_counter                :integer          default(0)
#  verified                         :boolean          default(FALSE)
#  profile_image_url                :string(255)
#  name                             :string(255)
#  description                      :string(255)
#  friendships_update_started_at    :datetime
#  friendships_update_finished_at   :datetime
#  followerships_update_started_at  :datetime
#  followerships_update_finished_at :datetime
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  subscriber                       :boolean          default(FALSE)
#

class User < ActiveRecord::Base
  ##
  # TOC
  #   1) Field defaults
  #   2) Validations
  #   3) Associations (friends, followers)
  #   4) Friendship predicates
  #   5) Good friends
  #   6) Shared friends and followers
  #   7) Friendship instance methods of user
  #   8) User instance methods
  #   9) Mass-assignment whitelist

  ##
  # 1) Field defaults
  def verified
    self[:verified] || false
  end

  # Counter caches renamed to friends_counter
  # and followers_counter, as automatic counter caching
  # did not want to turn off otherwise
  def friends_count
    self[:friends_counter] || 0
  end

  def followers_count
    self[:followers_counter] || 0
  end

  # Truncate description
  def description=(new_description)
    self[:description] = new_description.squeeze.strip.slice(0, 250)
  end

  ##
  # 2) Valdations
  # Twitter unique user id,
  #   may not change
  validates :twitter_id,
            presence: true,
            numericality: true,
            uniqueness: true

  # Screen name (== Twitter login)
  #   unique, but may change
  # ALERT: This validation leads to a second SQL query checking for uniqueness
  # validates_uniqueness_of :screen_name, allow_nil: true

  # Description
  validates :description,
            length: {maximum: 253}

  ##
  # 3) Associations
  # Friends
  has_many  :friendships
  has_many  :friends,
            through: :friendships,
            uniq: true

  # Followers
  has_many  :followerships,
            class_name: 'Friendship',
            foreign_key: 'friend_id'
  has_many  :followers,
            through: :followerships,
            source: :user,
            uniq: true

  ##
  # Relationships twitter_ids
  def friends_twitter_ids
    @friends_twitter_ids ||= friends.select(:twitter_id).map(&:twitter_id)
  end

  def followers_twitter_ids
    @followers_twitter_ids ||= followers.select(:twitter_id).map(&:twitter_id)
  end

  ##
  # 4) Friendship predicates
  #
  # Is this user a friend of mine,
  # a user I follow?
  def is_friend?(user)
    friends_twitter_ids.include?(user.twitter_id)
  end

  # Is this user a follower of mine?
  def is_follower?(user)
    followers_twitter_ids.include?(user.twitter_id)
  end

  ##
  # Good friends
  # Friends that I am following who follow me back
  #
  # Does this friend I am following follow me too?
  def is_good_friend?(user)
    is_friend? && is_follower?
  end

  def good_friends
    friends & followers
  end

  ##
  # 5) Shared friends and followers
  #
  # Shared friends
  # Which users do both users follow?
  def shared_friends_with(user)
    # Array#& returns items that are included in both arrays
    self.friends & user.friends
  end

  # Shared followers
  # Which users are both users being followed by?
  def shared_followers_with(user)
    self.followers & user.followers
  end

  ##
  # # Removed # #

  # Total reach
  # Sum of followers_count of a user's followers
  # regardless of uniqueness
  def total_reach
    @reach ||= User.where(twitter_id: followers_twitter_ids).select(:followers_counter).map(&:followers_counter).sum
  end

  # prerequisite: followers of each of my followers have to be requested first
  def total_unique_reach
    @unique_reach ||= begin
      ids = []
      followers.each { |follower| ids << follower.followers.select(:twitter_id).map(&:twitter_id) }
      uniques = ids.flatten.uniq.length
    end
  end

  ##
  # 7) User instance methods

  # User attribute map
  # Which user attribute is associated
  # with which twitter instance field?
  # :key => :twitter_key
  USER_ATTRIBUTES = {
    twitter_id:         :id,
    screen_name:        :screen_name,
    name:               :name,
    friends_counter:    :friends_count,
    followers_counter:  :followers_count,
    verified:           :verified,
    profile_image_url:  :profile_image_url,
    description:        :description
  }

  # Retrieve user
  # Map and set attributes
  # and save user instance
  def retrieve_user
    # Retrieve user from twitter
    twitter_user = Twitter.user(twitter_id)
    # Set attributes
    map_and_set_user_attributes(twitter_user)
    # Save user instance
    self.save
  end

  # Map and set user attributes
  # from suitable twitter user instance
  def map_and_set_user_attributes(twitter_user)
    USER_ATTRIBUTES.each { |key, twitter_key| self.send("#{ key }=", twitter_user[twitter_key]) }
  end

  ##
  # Class Methods

  # Create or update from omniauth
  # Create user from omniauth if he registers as a subscriber
  # or update the record if it is already known
  def self.create_or_update_from_omniauth(omniauth)
    # Extract user info from omniauth
    twitter_user = omniauth.extra.raw_info

    # Find or create user
    user = User.find_or_create_by_twitter_id(twitter_user.id.to_i)

    # Map and set user attributes
    user.map_and_set_user_attributes(twitter_user)

    # Set 'subscriber' flag
    user.subscriber = true

    # Initialize user
    delay.initialize_subscriber_user(user.twitter_id)

    # Save user instance
    user.save
  end

  def self.initialize_subscriber_user(twitter_id)
    # Ensure that user exists
    User.find_or_create_by_twitter_id(twitter_id)

    # Retrieve followerships
    # and followers
    delay.retrieve_followerships(twitter_id)

    # Retrieve friendships
    # and friends
    delay.retrieve_friendships(twitter_id)
  end

  def self.retrieve_followerships(twitter_id, opts = {})
    # Set cursor default
    # # Twitter API: Cursor == -1 identifies first page in pagination
     opts.reverse_merge!({
        cursor: -1
      })

    # Find user
    user = User.find_by_twitter_id(twitter_id)

    # Set followerships_update_started_at timestamp
    # if the first page is going to be retrieved
    if opts.cursor == -1
      user.update_column(:followerships_update_started_at, Time.now.utc)
    end

    # Request follower ids
    begin
      res = Twitter.follower_ids(twitter_id, cursor: opts[:cursor])
    rescue Twitter::Error::NotFound
      return
    end

    # Update the last_active_at timestamp on retrieved relationships
    #
    followerships = user.followerships.where(user_id: res.ids)
    followerships.each { |f| f.update_column(:last_active_at, Time.now.utc)}
  end

  ##
  # 8) Mass-assignment whitelisting
  attr_accessible :twitter_id,
                  :screen_name,
                  :name,
                  :friends_count,
                  :followers_count,
                  :verified,
                  :profile_image_url,
                  :description
end
