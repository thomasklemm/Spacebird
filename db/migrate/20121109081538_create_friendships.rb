class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      # Association
      t.integer :user_id,   null: false
      t.integer :friend_id, null: false

      # Twitter ids
      t.integer :user_twitter_id,   null: false
      t.integer :friend_twitter_id, null: false

      # Activity
      t.boolean :is_active, default: true
      t.datetime :canceled_at

      t.timestamps
    end
    add_index :friendships, [:user_id, :friend_id]
    add_index :friendships, [:user_twitter_id, :friend_twitter_id]
  end
end
