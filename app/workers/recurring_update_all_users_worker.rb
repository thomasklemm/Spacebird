##
# Schedule updates in the queue for all User records
# that have been updated from Twitter more than 24 hours ago
# can be called every fifteen minutes or more
#
class RecurringUpdateAllUsersWorker
  include Sidekiq::Worker

  def perform
    twitter_ids = []

    # Select all twitter_ids from users who have been updated_from_twitter_at more than a day ago
    User.where('updated_from_twitter_at < ?', 1.day.ago).select(:twitter_id).find_in_batches(batch_size: 5000) do |users|
      twitter_ids << users.map(&:twitter_id) if users.present?
    end

    # Select new users
    new_users = User.where(updated_from_twitter_at: nil).select(:twitter_id)
    twitter_ids << new_users.map(&:twitter_id) if new_users.present?

    # Flatten twitter_ids and ensure uniqueness
    twitter_ids = twitter_ids.flatten.uniq

    # Schedules updates for each user in batches of 100
    User.retrieve_users(twitter_ids)
    return
  end
end
