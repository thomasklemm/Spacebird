class CreateTokens < ActiveRecord::Migration
  def change
    create_table :tokens do |t|
      t.belongs_to :subscriber
      t.integer :twitter_id
      t.string :token
      t.string :secret

      t.timestamps
    end
    add_index :tokens, :subscriber_id
    add_index :tokens, :twitter_id
  end
end
