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

ActiveRecord::Schema.define(:version => 20150527174513) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "admin_users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "comments", :force => true do |t|
    t.text     "comment"
    t.integer  "rating_id"
    t.integer  "user_id"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.boolean  "is_anonymous_comment", :default => false
  end

  create_table "flagged_boxes", :force => true do |t|
    t.boolean  "is_flagged"
    t.integer  "user_id"
    t.integer  "tag_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "flagged_drops", :force => true do |t|
    t.boolean  "is_flagged"
    t.integer  "user_id"
    t.integer  "rating_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "messages", :force => true do |t|
    t.integer  "code"
    t.string   "status"
    t.string   "detail"
    t.string   "custom_message"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "notifications", :force => true do |t|
    t.integer  "user_id"
    t.integer  "tag_id"
    t.integer  "rating_id"
    t.integer  "comment_id"
    t.integer  "reveal_id"
    t.boolean  "status"
    t.string   "object_name"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.boolean  "is_seen"
    t.integer  "sender_id"
    t.boolean  "is_view"
  end

  create_table "ratings", :force => true do |t|
    t.integer  "rating"
    t.integer  "tag_id"
    t.string   "sub_rating"
    t.text     "comment"
    t.boolean  "is_anonymous_rating"
    t.boolean  "is_post_to_wall"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "rating_like_count",   :default => 0
    t.integer  "user_id"
    t.string   "audio"
    t.string   "audio_duration"
    t.string   "audio_file_url"
    t.integer  "reveal_id"
    t.boolean  "is_flagged",          :default => false
  end

  create_table "reveals", :force => true do |t|
    t.boolean  "status"
    t.integer  "user_id"
    t.integer  "rating_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "receiver_id"
  end

  create_table "tags", :force => true do |t|
    t.string   "tag_line"
    t.string   "tag_title"
    t.text     "tag_description"
    t.datetime "open_date"
    t.datetime "close_date"
    t.boolean  "is_private"
    t.boolean  "is_allow_anonymous"
    t.boolean  "is_post_to_wall"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.integer  "user_id"
    t.boolean  "is_locked"
    t.datetime "updated_time"
    t.integer  "rating_id"
    t.boolean  "is_flagged",         :default => false
    t.datetime "expiry_time"
  end

  add_index "tags", ["rating_id"], :name => "index_tags_on_rating_id"
  add_index "tags", ["user_id"], :name => "index_tags_on_user_id"

  create_table "tests", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name_string"
    t.integer  "age"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "user_follows", :force => true do |t|
    t.integer  "user_id"
    t.integer  "follow_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "is_accepted"
    t.boolean  "is_approved", :default => true
  end

  create_table "user_messages", :force => true do |t|
    t.integer  "sender_id"
    t.integer  "receiver_id"
    t.text     "message"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "user_ratings", :force => true do |t|
    t.integer  "rating_id"
    t.integer  "user_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "is_like",    :default => false
  end

  create_table "user_unfollows", :force => true do |t|
    t.integer  "user_id"
    t.integer  "unfollow_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "full_name"
    t.string   "phone"
    t.string   "gender"
    t.string   "location"
    t.string   "photo"
    t.string   "user_name"
    t.string   "device_token"
    t.string   "facebook_user_id"
    t.string   "twitter_user_id"
    t.string   "email",                  :default => "",    :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "authentication_token"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "about_me"
    t.boolean  "is_public_profile",      :default => true
    t.boolean  "is_following",           :default => false
    t.boolean  "is_follower",            :default => false
    t.boolean  "merged_account"
    t.boolean  "blank_password"
    t.integer  "reveal_id"
    t.boolean  "is_email_confirmed",     :default => false
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.boolean  "is_password_blank",      :default => false
    t.integer  "badge_count",            :default => 0
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token", :unique => true
  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
