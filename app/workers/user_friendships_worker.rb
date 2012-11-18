##
# Retrieve User Friendships
#
# Takes a twitter_id
# Retrieve twitter_ids of friends
# adds new friendships to database
# instructs retrieving of new twitter users
#
class UserFriendshipsWorker
  include Sidekiq::Worker

  # Retrieve friends twitter_ids
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

    # Set friendships_update_started_at timestamp
    # if the first page is going to be retrieved
    if opts[:cursor] == -1
      user.update_column(:friendships_update_started_at, Time.now.utc)
    end

    # Request friend ids
    begin
       result = TwitterClient.random.friend_ids(twitter_id, cursor: opts[:cursor])
       friend_twitter_ids = result.ids
    rescue Twitter::Error::NotFound
      return
    end

    # Update the last_active_at timestamp on retrieved relationships
    # (use friend_id in friendship case here)
    user_friendships = user.friendships.where(friend_twitter_id: friend_twitter_ids)
    user_friendships.each do |f|
      # REVIEW: Maybe an update_all is possible? (1 - 100 SQL calls could replace up to 5000)
      f.update_column(:last_active_at, Time.now.utc)
    end

    # Load next page asyncronously (delayed)
    # if there is any
    if result.next_cursor != 0
      # (delay)
      UserFriendshipsWorker.perform_async(twitter_id, cursor: result.next_cursor)
    end

    # Create or find friend
    # and add friendship
    # if not already present
    current_friend_ids = user_friendships.map(&:friend_twitter_id)

    friend_twitter_ids.each do |friend_twitter_id|
      unless current_friend_ids.include?(friend_twitter_id)
        # Find or create friend
        friend = User.find_or_initialize_by_twitter_id(friend_twitter_id)

        # Add friend_twitter_id to new_user_twitter_ids array
        if friend.new_record?
          new_user_twitter_ids << friend_twitter_id

          # Save record
          # so that 'id' is issued
          friend.save
        end

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
      UserFlagOutdatedFriendshipsWorker.perform_async(twitter_id)
    end

    # Retrieve users that are new
    # (splitted up in batches of 1000 in retrieve_users, and delayed there)
    # (do not delay, argument size up to 5000 twitter_ids)
    User.retrieve_users(new_user_twitter_ids)
    return
  end
end
