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
#  updated_from_twitter_at          :datetime
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  subscriber                       :boolean          default(FALSE)
#

