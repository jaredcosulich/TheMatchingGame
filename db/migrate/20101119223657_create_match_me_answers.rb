class CreateMatchMeAnswers < ActiveRecord::Migration
  def self.up
    create_table :match_me_answers do |t|
      t.integer :player_id
      t.integer :game_id
      t.integer :target_photo_id
      t.integer :other_photo_id
      t.string :answer

      t.timestamps
    end
    add_index :match_me_answers, :player_id
    add_index :match_me_answers, :target_photo_id
  end

  def self.down
    drop_table :match_me_answers
  end
end
