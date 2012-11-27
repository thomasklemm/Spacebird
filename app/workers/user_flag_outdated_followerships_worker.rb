##
# Flag outdated followerships for given twitter_id
# by setting their is_active flag to false
#
class UserFlagOutdatedFollowershipsWorker
  include Sidekiq::Worker

  # Flag outdated relationships
  # by setting their is_active flag to false
  def perform(twitter_id)
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
    return
  end
end
