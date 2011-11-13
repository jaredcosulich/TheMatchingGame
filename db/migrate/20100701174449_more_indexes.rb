class MoreIndexes < ActiveRecord::Migration

  def self.up
    add_index :score_events, [:event_id, :event_type]
    add_index :answers, [:game_id, :combo_id]
    add_index :photos, [:player_id]
  end

  def self.down
    remove_index :photos, [:player_id]
    remove_index :answers, [:game_id, :combo_id]
    remove_index :score_events, [:event_id, :event_type]
  end
end
