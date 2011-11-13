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

ActiveRecord::Schema.define(:version => 20110405014604) do

  create_table "answers", :force => true do |t|
    t.integer  "game_id",    :null => false
    t.string   "answer",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "combo_id"
    t.datetime "viewed_at"
    t.string   "kind"
    t.integer  "player_id"
  end

  add_index "answers", ["combo_id"], :name => "index_answers_on_combo_id"
  add_index "answers", ["game_id", "combo_id"], :name => "index_answers_on_game_id_and_combo_id"
  add_index "answers", ["game_id"], :name => "index_answers_on_game_id"
  add_index "answers", ["player_id"], :name => "index_answers_on_player_id"

  create_table "challenge_combos", :force => true do |t|
    t.integer  "challenge_id"
    t.integer  "combo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "challenge_players", :force => true do |t|
    t.integer  "challenge_id"
    t.integer  "player_id"
    t.integer  "score"
    t.string   "email"
    t.string   "fb_id"
    t.string   "name"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "completed_at"
    t.integer  "correct_count", :default => 0
  end

  create_table "challenges", :force => true do |t|
    t.integer  "creator_id"
    t.string   "name"
    t.text     "invitation_text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "clubs", :force => true do |t|
    t.string   "title"
    t.string   "permalink"
    t.integer  "interests_count", :default => 0
    t.boolean  "verified"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "combo_actions", :force => true do |t|
    t.integer  "combo_id",   :null => false
    t.integer  "photo_id",   :null => false
    t.string   "action",     :null => false
    t.text     "message"
    t.datetime "viewed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "combo_scores", :force => true do |t|
    t.integer "combo_id"
    t.integer "photo_id"
    t.integer "yes_count"
    t.integer "no_count"
    t.integer "vote_count"
    t.integer "yes_percent"
    t.boolean "active"
    t.integer "response"
    t.integer "other_photo_id"
    t.boolean "other_photo_approved"
    t.integer "other_response"
    t.integer "score"
  end

  add_index "combo_scores", ["combo_id", "photo_id"], :name => "index_combo_scores_on_combo_id_and_photo_id", :unique => true

  create_table "combos", :force => true do |t|
    t.integer  "photo_one_id",                           :null => false
    t.integer  "photo_two_id",                           :null => false
    t.integer  "yes_count",            :default => 0
    t.integer  "no_count",             :default => 0
    t.integer  "yes_percent",          :default => 0
    t.boolean  "active",               :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "inactivated_at"
    t.datetime "state_changed_at"
    t.datetime "photo_one_emailed_at"
    t.datetime "photo_two_emailed_at"
    t.string   "creation_reason"
    t.datetime "archived_at"
  end

  create_table "couple_friends", :force => true do |t|
    t.integer  "combo_id"
    t.integer  "other_combo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "crops", :force => true do |t|
    t.integer "photo_id"
    t.integer "x"
    t.integer "y"
    t.integer "w"
    t.integer "h"
    t.integer "rotation", :default => 0
  end

  create_table "crowdflower_jobs", :force => true do |t|
    t.integer  "user_id"
    t.integer  "job_id"
    t.string   "job_title"
    t.string   "conversion_id"
    t.integer  "amount"
    t.integer  "adjusted_amount"
    t.text     "initiate_payload"
    t.text     "complete_payload"
    t.datetime "completed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "crowdflower_jobs", ["conversion_id"], :name => "index_crowdflower_jobs_on_conversion_id"
  add_index "crowdflower_jobs", ["user_id"], :name => "index_crowdflower_jobs_on_user_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.text     "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "email_preferences", :force => true do |t|
    t.integer  "user_id"
    t.boolean  "awaiting_response",   :default => true, :null => false
    t.boolean  "prediction_progress", :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emailings", :force => true do |t|
    t.integer  "user_id"
    t.string   "email_name"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "params"
  end

  create_table "facebook_profiles", :force => true do |t|
    t.integer  "player_id"
    t.text     "fb_info"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flickr_photos", :force => true do |t|
    t.string   "flickr_url"
    t.integer  "photo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "games", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "player_id"
    t.integer  "challenge_player_id"
  end

  add_index "games", ["created_at"], :name => "index_games_on_created_at"
  add_index "games", ["player_id"], :name => "index_games_on_player_id"

  create_table "help_responses", :force => true do |t|
    t.integer  "player_id"
    t.string   "code"
    t.text     "feedback"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "interests", :force => true do |t|
    t.integer  "player_id"
    t.string   "title"
    t.integer  "club_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "interests", ["club_id"], :name => "index_interests_on_club_id"
  add_index "interests", ["player_id"], :name => "index_interests_on_player_id"

  create_table "link_clicks", :force => true do |t|
    t.integer  "link_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "links", :force => true do |t|
    t.string   "source_type"
    t.integer  "source_id"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "match_me_answers", :force => true do |t|
    t.integer  "player_id"
    t.integer  "game_id"
    t.integer  "target_photo_id"
    t.integer  "other_photo_id"
    t.string   "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "game"
  end

  add_index "match_me_answers", ["game"], :name => "index_match_me_answers_on_game"
  add_index "match_me_answers", ["other_photo_id"], :name => "index_match_me_answers_on_other_photo_id"
  add_index "match_me_answers", ["player_id"], :name => "index_match_me_answers_on_player_id"
  add_index "match_me_answers", ["target_photo_id", "other_photo_id"], :name => "index_match_me_answers_on_target_photo_id_and_other_photo_id"
  add_index "match_me_answers", ["target_photo_id"], :name => "index_match_me_answers_on_target_photo_id"

  create_table "photo_pairs", :force => true do |t|
    t.integer  "photo_id"
    t.integer  "other_photo_id"
    t.integer  "combo_id"
    t.integer  "distance"
    t.integer  "age_difference"
    t.integer  "bucket_difference"
    t.integer  "photo_answer_yes",              :default => 0, :null => false
    t.integer  "photo_answer_no",               :default => 0, :null => false
    t.integer  "other_photo_answer_yes",        :default => 0, :null => false
    t.integer  "other_photo_answer_no",         :default => 0, :null => false
    t.integer  "friend_answer_yes",             :default => 0, :null => false
    t.integer  "friend_answer_no",              :default => 0, :null => false
    t.integer  "yes_count",                     :default => 0, :null => false
    t.integer  "no_coucont",                      :default => 0, :null => false
    t.integer  "vote_count",                    :default => 0, :null => false
    t.integer  "yes_percent",                   :default => 0, :null => false
    t.integer  "response",                      :default => 0, :null => false
    t.integer  "other_response",                :default => 0, :null => false
    t.integer  "photo_message_count",           :default => 0, :null => false
    t.integer  "other_photo_message_count",     :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "connection_score"
    t.decimal  "correlation_score"
    t.datetime "other_photo_match_revealed_at"
  end

  add_index "photo_pairs", ["combo_id"], :name => "index_photo_pairs_on_combo_id"
  add_index "photo_pairs", ["other_photo_id"], :name => "index_photo_pairs_on_other_photo_id"
  add_index "photo_pairs", ["other_photo_match_revealed_at"], :name => "index_photo_pairs_on_other_photo_match_revealed_at"
  add_index "photo_pairs", ["photo_id", "other_photo_id"], :name => "index_photo_pairs_on_photo_id_and_other_photo_id", :unique => true
  add_index "photo_pairs", ["photo_id"], :name => "index_photo_pairs_on_photo_id"

  create_table "photos", :force => true do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "gender",                                         :null => false
    t.boolean  "image_processing"
    t.string   "current_state",       :default => "unconfirmed", :null => false
    t.string   "rejected_reason"
    t.integer  "player_id",                                      :null => false
    t.integer  "couple_combo_id"
    t.integer  "bucket"
    t.integer  "activity_adjustment", :default => 0
    t.datetime "priority_until"
  end

  add_index "photos", ["player_id"], :name => "index_photos_on_player_id"
  add_index "photos", ["priority_until"], :name => "index_photos_on_priority_until"

  create_table "player_stats", :force => true do |t|
    t.integer  "player_id"
    t.integer  "game_count"
    t.integer  "answer_count"
    t.integer  "yes_count"
    t.integer  "no_count"
    t.integer  "yes_percent"
    t.integer  "correct_count"
    t.integer  "incorrect_count"
    t.integer  "accuracy"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "answer_weight",   :precision => 5, :scale => 3
  end

  add_index "player_stats", ["player_id"], :name => "index_player_stats_on_player_id", :unique => true

  create_table "players", :force => true do |t|
    t.string   "gender",                 :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "preferred_profile_type"
    t.integer  "preferred_profile_id"
    t.string   "geo_name"
    t.decimal  "geo_lat",                             :precision => 9, :scale => 6
    t.decimal  "geo_lng",                             :precision => 9, :scale => 6
    t.boolean  "connectable",                                                       :default => true, :null => false
    t.integer  "pages_visited",                                                     :default => 0,    :null => false
  end

  create_table "priorities", :force => true do |t|
    t.integer  "photo_id"
    t.integer  "user_id"
    t.integer  "credits_applied"
    t.integer  "days_purchased"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "profiles", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "location_name"
    t.decimal  "location_lat",       :precision => 9, :scale => 6
    t.decimal  "location_lng",       :precision => 9, :scale => 6
    t.date     "birthdate"
    t.string   "sexual_orientation"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "player_id",                                        :null => false
    t.text     "about"
    t.text     "first_date"
  end

  create_table "question_answers", :force => true do |t|
    t.integer  "question_id"
    t.integer  "player_id"
    t.text     "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "questions", :force => true do |t|
    t.integer  "player_id"
    t.string   "title"
    t.string   "permalink"
    t.boolean  "long_answers",      :default => false
    t.boolean  "verified",          :default => false
    t.string   "suggested_answers"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "referrals", :force => true do |t|
    t.integer  "referrer_id"
    t.integer  "player_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "locale"
  end

  add_index "referrals", ["player_id"], :name => "index_referrals_on_player_id"

  create_table "referrers", :force => true do |t|
    t.string   "url"
    t.string   "uid"
    t.string   "title"
    t.string   "note"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "responses", :force => true do |t|
    t.integer  "combo_id",                                               :null => false
    t.string   "photo_one_answer"
    t.string   "photo_two_answer"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "photo_one_answered_at"
    t.datetime "photo_two_answered_at"
    t.integer  "photo_one_rating"
    t.integer  "photo_two_rating"
    t.boolean  "photo_one_unlocked",                  :default => false
    t.boolean  "photo_two_unlocked",                  :default => false
    t.string   "creation_reason",       :limit => 16
    t.datetime "revealed_at"
    t.datetime "photo_one_archived_at"
    t.datetime "photo_two_archived_at"
  end

  add_index "responses", ["combo_id"], :name => "index_responses_on_combo_id", :unique => true

  create_table "score_events", :force => true do |t|
    t.integer  "player_id"
    t.string   "type"
    t.integer  "event_id"
    t.string   "event_type"
    t.datetime "event_at"
    t.integer  "answer_count"
    t.integer  "correct_count"
    t.integer  "incorrect_count"
    t.integer  "score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "score_events", ["event_id", "event_type"], :name => "index_score_events_on_event_id_and_event_type"
  add_index "score_events", ["player_id"], :name => "index_score_events_on_player_id"

  create_table "shares", :force => true do |t|
    t.integer  "player_id"
    t.string   "from"
    t.string   "type"
    t.text     "fb_ids"
    t.text     "emails"
    t.text     "message"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "social_gold_transactions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "amount"
    t.integer  "net_payout_amount"
    t.string   "premium_currency_label"
    t.integer  "premium_currency_amount"
    t.string   "offer_id"
    t.integer  "offer_amount"
    t.string   "offer_amount_iso_currency_code"
    t.string   "pegged_currency_label"
    t.integer  "pegged_currency_amount"
    t.string   "pegged_currency_amount_iso_currency_code"
    t.integer  "user_balance"
    t.string   "socialgold_transaction_id"
    t.string   "external_ref_id"
    t.string   "socialgold_transaction_status"
    t.string   "event_type"
    t.string   "version"
    t.text     "extra_fields"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tapjoy_offers", :force => true do |t|
    t.integer  "user_id"
    t.integer  "tapjoy_id"
    t.integer  "credits"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "source_id"
    t.string   "source_type"
    t.integer  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "external_ref_id"
  end

  add_index "transactions", ["external_ref_id"], :name => "index_transactions_on_external_ref_id", :unique => true

  create_table "users", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "fb_id",             :limit => 8
    t.string   "email"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.integer  "login_count",                    :default => 0,     :null => false
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip"
    t.string   "current_login_ip"
    t.integer  "player_id",                                         :null => false
    t.string   "perishable_token",               :default => "",    :null => false
    t.boolean  "terms_of_service",               :default => false
    t.integer  "credits"
    t.datetime "subscribed_until"
    t.integer  "emails_sent",                    :default => 0,     :null => false
    t.datetime "last_emailed_at"
    t.datetime "deleted_at"
    t.text     "deleted_reason"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

end
