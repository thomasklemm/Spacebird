# == Schema Information
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

describe User do
  it '#saves history on updating counters' do
    u = User.create(twitter_id: 123)

    # 3 days ago
    Timecop.travel(3.days.ago) do
      u.update_attributes({
          followers_counter: 1,
          friends_counter: 2,
          statuses_counter: 3
        }, without_protection: true)

      h = u.user_history(true)
      h.should_not == nil

      h.followers[Date.current].should eq(1)
      h.friends[Date.current].should eq(2)
      h.statuses[Date.current].should eq(3)

      u.update_attributes({
          followers_counter: 2,
          friends_counter: 3
        }, without_protection: true)

      h = u.user_history(true)
      h.should_not == nil

      h.followers[Date.current].should eq(2)
      h.friends[Date.current].should eq(3)
      h.statuses[Date.current].should eq(3)
    end

    # 2 days ago
    Timecop.travel(2.days.ago) do
      u.update_attributes({
          followers_counter: 4,
          friends_counter: 4
        }, without_protection: true)

      h = u.user_history(true)
      h.should_not == nil

      h.followers[Date.current].should eq(4)
      h.friends[Date.current].should eq(4)
      h.statuses[Date.current].should eq(3)
    end

    # Today
    u.update_attributes({
        followers_counter: 5,
        friends_counter: 5
      }, without_protection: true)

    h = u.user_history(true)
    h.should_not == nil

    h.followers[Date.current].should eq(5)
    h.friends[Date.current].should eq(5)
    h.statuses[Date.current].should eq(3)
  end
end
