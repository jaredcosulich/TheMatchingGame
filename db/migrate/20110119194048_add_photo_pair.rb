class AddPhotoPair < ActiveRecord::Migration
  def self.up
    create_table :photo_pairs, :force => true do |t|
      t.integer "photo_id"
      t.integer "other_photo_id"

      t.integer "combo_id"

      t.integer "distance"
      t.integer "age_difference"
      t.integer "bucket_difference"

      t.integer "photo_answer_yes", :default => 0, :null => false
      t.integer "photo_answer_no", :default => 0, :null => false
      t.integer "other_photo_answer_yes", :default => 0, :null => false
      t.integer "other_photo_answer_no", :default => 0, :null => false

      t.integer "friend_answer_yes", :default => 0, :null => false
      t.integer "friend_answer_no", :default => 0, :null => false

      t.integer "yes_count", :default => 0, :null => false
      t.integer "no_count", :default => 0, :null => false
      t.integer "vote_count", :default => 0, :null => false
      t.integer "yes_percent", :default => 0, :null => false

      t.integer "response", :default => 0, :null => false
      t.integer "other_response", :default => 0, :null => false

      t.integer "photo_message_count", :default => 0, :null => false
      t.integer "other_photo_message_count", :default => 0, :null => false

      t.timestamps
    end

    add_index :photo_pairs, :photo_id
    add_index :photo_pairs, [:photo_id, :other_photo_id], :unique => true
    add_index :photo_pairs, :combo_id
  end

  def self.down
    drop_table :photo_pairs
  end
end
