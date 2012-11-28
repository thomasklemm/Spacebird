class FakeDataWorker
  include Sidekiq::Worker

  # Generate huge amounts of fake data
  # and store it on Heroku Postgres
  # Let's see how it performs! :-D
  def perform(n = 1000)
    (n/100).times do
      ActiveRecord::Base.transaction do
        100.times { create_fake_user rescue false}
      end
    end

    # always exit without retry, even if last save fails
    return true
  end

  def create_fake_user
    u = User.new
    u.twitter_id = fake_twitter_id

    u.name = fake_name
    u.screen_name = fake_screen_name
    u.description = fake_description

    u.profile_image_url = fake_url

    u.friends_counter = fake_counter
    u.followers_counter = fake_counter
    u.statuses_counter = fake_counter

    u.updated_from_twitter_at = Time.zone.now
    u.friendships_update_started_at = Time.zone.now - 2.days
    u.followerships_update_started_at = Time.zone.now - 1.day

    u.save

    # Another save to insert history
    # For more history time-traveling might come in handy :-D
    u.friends_counter = fake_counter
    u.followers_counter = fake_counter
    u.statuses_counter = fake_counter

    u.save
  end

  def fake_twitter_id # must be unique
    rand(2147483647) # highest postgres integer
  end

  def fake_screen_name # must be unique, too
    rand(10**50).to_s(36)
  end

  def fake_name
    Faker::NameDE.name
  end

  def fake_description
    Faker::HipsterIpsum.paragraph
  end

  def fake_counter
    rand(10000)
  end

  def fake_url
    Faker::Internet.http_url
  end
end
