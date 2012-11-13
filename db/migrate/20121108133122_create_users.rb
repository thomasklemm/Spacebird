class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      # Basic identifiers
      # Unique Twitter id
      t.integer :twitter_id, null: false
      # Screen_name is Twitter login, is unique, but may change
      t.string :screen_name

      # Unusual naming because otherwise issues
      # with automatic counter cache
      # even if counter cache set to false
      t.integer :friends_counter, default: 0
      t.integer :followers_counter, default: 0

      # Twitter verified user
      t.boolean :verified, default: false

      # Twitter avatar
      t.string :profile_image_url

      # Twitter name and description
      t.string :name
      t.string :description

      # Times of updates of associations
      t.datetime :friendships_update_started_at
      t.datetime :friendships_update_finished_at

      t.datetime :followerships_update_started_at
      t.datetime :followerships_update_finished_at

      # Further timestamps
      t.datetime :updated_from_twitter_at

      t.timestamps
    end
    add_index :users, :twitter_id, unique: true
    add_index :users, :screen_name, unique: true
  end
end
