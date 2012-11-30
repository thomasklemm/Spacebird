##
# Retrieve users from Twitter
# and update user records
# in batches of up to 100 twitter_ids
#
class UserLookupsWorker
  include Sidekiq::Worker

  def perform(*twitter_ids)
    # Take single ids as arguments as well as arrays
    twitter_ids = twitter_ids.flatten

    # Get users from Twitter
    twitter_users = TwitterClient.random.users(twitter_ids, method: :get)

    # Iterate over twitter_users
    twitter_users.each do |twitter_user|
      # Find or create user
      user = User.find_or_create_by_twitter_id(twitter_user.id)

      # Map and set user attributes
      user.map_and_set_user_attributes(twitter_user)

      # Set updated_from_twitter_at timestamp
      user.updated_from_twitter_at = Time.zone.now

      # Save user
      user.save
    end
    return
  end
end
