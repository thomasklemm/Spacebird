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
  #   5) Shared friends and followers
  #   6) User instance methods
  #   7) User class methods
  #   8) Followerships
  #   9) Friendships
  #   10) Experimental
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
    # (delay)
    delay.initialize_subscriber_user(user.twitter_id)

    # Save user instance
    user.save
  end

  # Initialize subscriber as a user
  def self.initialize_subscriber_user(twitter_id)
    # Ensure that user exists
    User.find_or_create_by_twitter_id(twitter_id)

    # Retrieve followerships and followers
    # (delay)
    delay.retrieve_followerships(twitter_id)

    # Retrieve friendships and friends
    # (delay)
    delay.retrieve_friendships(twitter_id)
    return
  end

  ##
  # 8) Followerships
  #
  # Retrieve followerships
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
    if opts[:cursor] == -1
      user.update_column(:followerships_update_started_at, Time.now.utc)
    end

    # Request follower ids
    begin
       result = Twitter.follower_ids(twitter_id, cursor: opts[:cursor])
       follower_twitter_ids = result.ids
    rescue Twitter::Error::NotFound
      return
    end

    # Update the last_active_at timestamp on retrieved relationships
    # (use friend_id in friendship case here)
    followerships = user.followerships.where(user_twitter_id: follower_twitter_ids)
    followerships.each do |f|
      # REVIEW: Maybe an update_all is possible? (1 - 100 SQL calls could replace up to 5000)
      f.update_column(:last_active_at, Time.now.utc)
    end

    # Load next page asyncronously (delayed)
    # if there is any
    if result.next_cursor != 0
      # (delay)
      delay.retrieve_followerships(twitter_id, cursor: result.next_cursor)
    end

    # Create or find follower
    # and add followership
    # if not already present
    current_follower_ids = followerships.map(&:user_twitter_id)

    follower_twitter_ids.each do |follower_twitter_id|
      unless current_follower_ids.include?(follower_twitter_id)
        # Find or create follower
        follower = User.find_or_create_by_twitter_id(follower_twitter_id)

        # Add followership
        user.followerships.create do |f|
          # The follower is the user in this case...
          f.user_id           = follower.id
          f.user_twitter_id   = follower.twitter_id

          # ... who is a friend of the current user
          f.friend_id         = user.id
          f.friend_twitter_id = user.twitter_id

          # Set first_active_at timestamp
          f.first_active_at   = Time.now.utc
        end
      end
    end

    # Flag inactive followerships
    # which includes setting the user's followerships_update_finished_at flag when finished
    if result.next_cursor == 0
      # (delay)
      delay.flag_outdated_followerships(twitter_id)
    end
    return
  end

  # Flag outdated relationships
  # by setting their is_active flag to false
  def self.flag_outdated_followerships(twitter_id)
    # Followerships_update_started_at timestamp
    user      = User.find_by_twitter_id(twitter_id)
    timestamp = user.followerships_update_started_at

    # Find outdated followerships
    outdated_followerships = user.followerships.where("last_active_at < ?", timestamp)

    # Set is_active flag of outdated followerships to false
    outdated_followerships.each do |followership|
      followership.update_column(:is_active, false)
    end

    # Set follwerships_update_finished_at flag on user
    user.update_column(:followerships_update_finished_at, Time.now.utc)
  end

  ##
  # 9) Friendships
  #
  # Retrieve friendships
  def self.retrieve_friendships(twitter_id, opts = {})
    # Set cursor default
    # # Twitter API: Cursor == -1 identifies first page in pagination
    opts.reverse_merge!({
        cursor: -1
      })

    # Find user
    user = User.find_by_twitter_id(twitter_id)

    # Set friendships_update_started_at timestamp
    # if the first page is going to be retrieved
    if opts[:cursor] == -1
      user.update_column(:friendships_update_started_at, Time.now.utc)
    end

    # Request friend ids
    begin
       result = Twitter.friend_ids(twitter_id, cursor: opts[:cursor])
       friend_twitter_ids = result.ids
    rescue Twitter::Error::NotFound
      return
    end

    # Update the last_active_at timestamp on retrieved relationships
    # (use friend_id in friendship case here)
    friendships = user.friendships.where(friend_twitter_id: friend_twitter_ids)
    friendships.each do |f|
      # REVIEW: Maybe an update_all is possible? (1 - 100 SQL calls could replace up to 5000)
      f.update_column(:last_active_at, Time.now.utc)
    end

    # Load next page asyncronously (delayed)
    # if there is any
    if result.next_cursor != 0
      # (delay)
      delay.retrieve_friendships(twitter_id, cursor: result.next_cursor)
    end

    # Create or find friend
    # and add friendship
    # if not already present
    current_friend_ids = friendships.map(&:friend_twitter_id)

    friend_twitter_ids.each do |friend_twitter_id|
      unless current_friend_ids.include?(friend_twitter_id)
        # Find or create friend
        friend = User.find_or_create_by_twitter_id(friend_twitter_id)

        # Add friendship
        user.friendships.create do |f|
          # The user is the user in this case...
          f.user_id           = user.id
          f.user_twitter_id   = user.twitter_id

          # ... who has the friend as a friend
          f.friend_id         = friend.id
          f.friend_twitter_id = friend.twitter_id

          # Set first_active_at timestamp
          f.first_active_at   = Time.now.utc
        end
      end
    end

    # Flag inactive friendships
    # which includes setting the user's friendships_update_finished_at flag when finished
    if result.next_cursor == 0
      # (delay)
      delay.flag_outdated_friendships(twitter_id)
    end
    return
  end

  # Flag outdated relationships
  # by setting their is_active flag to false
  def self.flag_outdated_friendships(twitter_id)
    # friendships_update_started_at timestamp
    user      = User.find_by_twitter_id(twitter_id)
    timestamp = user.friendships_update_started_at

    # Find outdated friendships
    outdated_friendships = user.friendships.where("last_active_at < ?", timestamp)

    # Set is_active flag of outdated friendships to false
    outdated_friendships.each do |friendship|
      friendship.update_column(:is_active, false)
    end

    # Set follwerships_update_finished_at flag on user
    user.update_column(:friendships_update_finished_at, Time.now.utc)
  end

  ##
  # 10) Experimental

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
  # 11) Mass-assignment whitelisting
  attr_accessible :twitter_id,
                  :screen_name,
                  :name,
                  :friends_count,
                  :followers_count,
                  :verified,
                  :profile_image_url,
                  :description
end
