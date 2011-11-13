class CreateIndexesForSomeForeignKeys < ActiveRecord::Migration
  def self.up
    add_index :answers, :game_id
    add_index :answers, :combo_id

    add_index :games, :player_id
    add_index :score_events, :player_id

    add_index :responses, :combo_id, :unique => true
  end

  def self.down
    remove_index :responses, :combo_id


    remove_index :score_events, :player_id
    remove_index :games, :player_id

    remove_index :answers, :combo_id
    remove_index :answers, :game_id
  end
end
