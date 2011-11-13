class CreatePlayerStats < ActiveRecord::Migration
  def self.up
    create_table :player_stats do |t|
      t.integer :player_id
      t.integer :game_count
      t.integer :answer_count
      t.integer :yes_count
      t.integer :no_count
      t.integer :yes_percent
      t.integer :correct_count
      t.integer :incorrect_count
      t.integer :accuracy

      t.timestamps
    end
    add_index :player_stats, [:player_id], :unique => true
  end

  def self.down
    drop_table :player_stats
  end
end
