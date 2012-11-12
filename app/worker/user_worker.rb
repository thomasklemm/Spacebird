class UserWorker
  ##
  # Modules
  include Sidekiq::Worker

  # Sidekiq Worker perform
  # call via perform_async(*args)
  def perform(*args)

    # Normalize ids so perform works with single ids as well as arrays
    ids = normalize_ids(args)

    # Request user information from Twitter
    twitter_users = retrieve_twitter_users(ids)

    # Update each user record
    twitter_users.each do |twitter_user|
      # Retrieve or initialize user instance
      user = User.find_or_initialize_by_twitter_id(twitter_user.id)

      # Map attributes
      mapped_attributes = User.map_twitter_attributes(twitter_user)

      # Assign attributes to user instance without saving record
      user.assign_attrib(mapped_attributes)

      # User has been initialized
      user.initialized = true
    end
  end

  ##
  # Normalize Twitter ids
  # so that perform accepts
  # - a single id as an integer,
  # - a single screen_name as a string,
  # - multiple integers as an array of integers,
  # - multiple screen_names as an array of strings
  #
  # Twitter gem will recognize output automatically
  def normalize_ids(*args)
    ids = []
    ids << args

    # Ensure that ids are unique
    ids.flatten.uniq
  end

  # Retrieve twitter user instances from Twitter
  # while choosing request endpoint per ids.length
  def retrieve_twitter_users(ids)
    begin
      if ids.instance_of?(Array) && ids.length == 1
        # Get request (users/show)
        # One user instance returned
        twitter_users = [Twitter.user(ids.first)]
      else
        # Post request (users/lookup)
        # Up to 100 user instances returned
        twitter_users = Twitter.users(ids)
      end
    rescue Twitter::Error::NotFound
      twitter_users = nil
    end

    return twitter_users
  end
end
