# == Schema Information
# Schema version: 20121119211120
#
# Table name: users
#
#  id                               :integer          not null, primary key
#  twitter_id                       :integer          not null
#  screen_name                      :string(255)
#  friends_counter                  :integer          default(0)
#  followers_counter                :integer          default(0)
#  statuses_counter                 :integer          default(0)
#  verified                         :boolean          default(FALSE)
#  profile_image_url                :string(255)
#  name                             :string(255)
#  description                      :text
#  friendships_update_started_at    :datetime
#  friendships_update_finished_at   :datetime
#  followerships_update_started_at  :datetime
#  followerships_update_finished_at :datetime
#  updated_from_twitter_at          :datetime
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  subscriber                       :boolean          default(FALSE)
#
# Indexes
#
#  index_users_on_screen_name  (screen_name) UNIQUE
#  index_users_on_twitter_id   (twitter_id) UNIQUE
#

class User < ActiveRecord::Base
  ##
  # TOC
  #   1) Field defaults
  #   2) Validations
  #   3) Associations (friends, followers)
  #   4) Friendship predicates
  #   5) Shared friends and followers
  #   6) User instance methods
  #   6a) User history
  #   7) User class methods
  #   8) Experimental
  #   9) Followerships
  #   10) Friendships
  #   11) Mass-assignment whitelist

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

  # Image url
  alias_attribute :image_url, :profile_image_url

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

  # Which of my friends follow me back?
  # TWEAK: Maybe load users by a more sophisticated SQL Query
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
  # 6) User instance methods

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
    # (delay)
    User.delay.perform_user_request(twitter_id)
  end

  #
  def self.perform_user_request(twitter_id)
    # Find user
    user = User.find_by_twitter_id(twitter_id)
    # Retrieve user from twitter
    twitter_user = TwitterClient.random.user(twitter_id)
    # Set attributes
    user.map_and_set_user_attributes(twitter_user)
    # Save user instance
    user.save
  end

  # Map and set user attributes
  # from suitable twitter user instance
  def map_and_set_user_attributes(twitter_user)
    USER_ATTRIBUTES.each { |key, twitter_key| self.send("#{ key }=", twitter_user[twitter_key]) }
  end

  # Retrieve user instances for twitter_ids in the background
  def self.retrieve_users(*twitter_ids)
    twitter_ids = twitter_ids.to_a.flatten.uniq

    # Slice off the first batch of 100 twitter_ids
    batch = twitter_ids.shift(100)

    # Perform user retrieval for this batch
    # (delay)
    UserLookupsWorker.perform_async(batch) if batch.present?

    # Rinse, repeat if there are still twitter_ids present
    retrieve_users(twitter_ids) if twitter_ids.present?
  end

  ##
  # UserLookupsWorker:
  #   Retrieves users in batches up to 100 from Twitter

  ##
  # 8) User history
  has_one :user_history

  # Write user history if statistical values change
  before_save :set_user_history

  def set_user_history
    return if new_record?

    # Create user history record unless it already exists
    create_user_history unless user_history.present?

    # Set historical values
    self.user_history.followers[Date.current] = followers_counter if followers_counter_changed?
    self.user_history.friends[Date.current]   = friends_counter   if friends_counter_changed?
    self.user_history.statuses[Date.current]  = statuses_counter  if statuses_counter_changed?

    # Save history
    self.user_history.save if user_history_changed?
  end

  # User history changes if any of the counters changes
  def user_history_changed?
    followers_counter_changed? || friends_counter_changed? || statuses_counter_changed?
  end

  ##
  # 7) User Class Methods

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
    # (delay) --> default queue needs decent priority
    #             to quickly initialize new subscribers
    delay.initialize_subscriber_user(user.twitter_id)

    # Save user instance
    user.save
  end

  # Initialize subscriber as a user
  def self.initialize_subscriber_user(twitter_id)
    # Ensure that user exists
    User.find_or_create_by_twitter_id(twitter_id)

    # Retrieve user
    # (delay)
    # REVIEW: THIS IS INEFFICIENT; AN API CALL WASTED
    # MAYBE EXTEND WORKER TO USE DIFFERENT ENDPOINT IN CASE OF ONLY A FEW IDS TO BE RETRIEVED
    # (to set updated_from_twitter_at, too)
    UserLookupsWorker.perform_async(twitter_id)

    # Retrieve followerships and followers
    # (delay)
    UserFollowershipsWorker.perform_async(twitter_id)

    # Retrieve friendships and friends
    # (delay)
    UserFriendshipsWorker.perform_async(twitter_id)
    return
  end

  ##
  # 8) Experimental

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
  # 9) Followerships
  # see: - UserFollowershipsWorker
  #          Retrieves followerships and followers for given twitter_id
  #      - UserFlagOutdatedFollowershipsWorker
  #          Flags outdated followerships for given twitter_id

  ##
  # 10) Friendships
  # see: - UserFriendshipsWorker
  #          Retrieves friendships and friends for given twitter_id
  #      - UserFlagOutdatedFriendshipsWorker
  #          Flags outdated friendships for given twitter_id

  ##
  # 11) Mass-assignment whitelisting
  attr_accessible :twitter_id,
                  :screen_name,
                  :name,
                  :friends_count,
                  :followers_count,
                  :verified,
                  :profile_image_url,
                  :image_url,
                  :description
end
