##
# Retrieve followerships and followers
# for user with given twitter_id
#
class UserFollowershipsWorker
  include Sidekiq::Worker

  # Retrieve followerships
  def perform(twitter_id, opts = {})
    # Set cursor default
    # # Twitter API: Cursor == -1 identifies first page in pagination
    opts.reverse_merge!({
        cursor: -1
      })

    # Array that new user twitter_ids will be pushed to
    new_user_twitter_ids = []

    # Find user
    user = User.find_by_twitter_id(twitter_id)

    # Set followerships_update_started_at timestamp
    # if the first page is going to be retrieved
    if opts[:cursor] == -1
      user.update_column(:followerships_update_started_at, Time.now.utc)
    end

    # Request follower ids
    begin
       result = TwitterClient.random.follower_ids(twitter_id, cursor: opts[:cursor])
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
      UserFollowershipsWorker.retrieve_followerships(twitter_id, cursor: result.next_cursor)
    end

    # Create or find follower
    # and add followership
    # if not already present
    current_follower_ids = followerships.map(&:user_twitter_id)

    follower_twitter_ids.each do |follower_twitter_id|
      unless current_follower_ids.include?(follower_twitter_id)
        # Find or create follower
        follower = User.find_or_initialize_by_twitter_id(follower_twitter_id)

        # Add friend_twitter_id to new_user_twitter_ids array
        if follower.new_record?
          new_user_twitter_ids << follower_twitter_id

          # Save record
          # so that 'id' is issued
          follower.save
        end

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
      UserFlagOutdatedFollowershipsWorker.perform_async(twitter_id)
    end

    # Retrieve users that are new
    # (splitted up in batches of 1000 in retrieve_users, and delayed there)
    # (do not delay, argument size up to 5000 twitter_ids)
    User.retrieve_users(new_user_twitter_ids)
    return
  end
end
