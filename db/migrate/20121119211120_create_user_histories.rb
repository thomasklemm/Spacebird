class CreateUserHistories < ActiveRecord::Migration
  def change
    create_table :user_histories do |t|
      t.integer :user_id, null: false
      # Serializable text columns
      t.text :followers
      t.text :friends
      t.text :statuses

      t.timestamps
    end
    add_index :user_histories, :user_id
  end
end
