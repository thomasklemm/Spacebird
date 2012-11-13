# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121113114229) do

  create_table "authentications", :force => true do |t|
    t.integer  "subscriber_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "authentications", ["subscriber_id"], :name => "index_authentications_on_subscriber_id"

  create_table "friendships", :force => true do |t|
    t.integer  "user_id",                             :null => false
    t.integer  "friend_id",                           :null => false
    t.integer  "user_twitter_id",                     :null => false
    t.integer  "friend_twitter_id",                   :null => false
    t.boolean  "is_active",         :default => true
    t.datetime "first_active_at"
    t.datetime "last_active_at"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  add_index "friendships", ["user_id", "friend_id"], :name => "index_friendships_on_user_id_and_friend_id"
  add_index "friendships", ["user_twitter_id", "friend_twitter_id"], :name => "index_friendships_on_user_twitter_id_and_friend_twitter_id"

  create_table "subscribers", :force => true do |t|
    t.string   "username"
    t.string   "name"
    t.string   "image_url"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "subscribers", ["remember_token"], :name => "index_subscribers_on_remember_token"
  add_index "subscribers", ["username"], :name => "index_subscribers_on_username", :unique => true

  create_table "tokens", :force => true do |t|
    t.integer  "subscriber_id"
    t.integer  "twitter_id"
    t.string   "token"
    t.string   "secret"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "tokens", ["subscriber_id"], :name => "index_tokens_on_subscriber_id"
  add_index "tokens", ["twitter_id"], :name => "index_tokens_on_twitter_id"

  create_table "users", :force => true do |t|
    t.integer  "twitter_id",                                          :null => false
    t.string   "screen_name"
    t.integer  "friends_counter",                  :default => 0
    t.integer  "followers_counter",                :default => 0
    t.boolean  "verified",                         :default => false
    t.string   "profile_image_url"
    t.string   "name"
    t.string   "description"
    t.datetime "friendships_update_started_at"
    t.datetime "friendships_update_finished_at"
    t.datetime "followerships_update_started_at"
    t.datetime "followerships_update_finished_at"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.boolean  "subscriber",                       :default => false
  end

  add_index "users", ["screen_name"], :name => "index_users_on_screen_name", :unique => true
  add_index "users", ["twitter_id"], :name => "index_users_on_twitter_id", :unique => true

end
