class CreateAuthentications < ActiveRecord::Migration
  def change
    create_table :authentications do |t|
      t.belongs_to :subscriber
      t.string :provider
      t.string :uid

      t.timestamps
    end
    add_index :authentications, :subscriber_id
  end
end
