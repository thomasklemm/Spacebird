##
# Flag outdated friendships for given twitter_id
# by setting their is_active flag to false
#
class UserFlagOutdatedFriendshipsWorker
  include Sidekiq::Worker

  # Flag outdated relationships
  # by setting their is_active flag to false
  def perform(twitter_id)
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
end
