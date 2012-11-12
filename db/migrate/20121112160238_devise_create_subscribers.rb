class DeviseCreateSubscribers < ActiveRecord::Migration
  def change
    create_table(:subscribers) do |t|
      ## Subscriber
      t.string :username, null: :false
      t.string :name
      t.string :image_url

      ## Rememberable
      t.string   :remember_token
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      # Timestamps
      t.timestamps
    end

    add_index :subscribers, :username, unique: true
    add_index :subscribers, :remember_token
  end
end
