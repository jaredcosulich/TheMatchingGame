class AddGameToMatchMe < ActiveRecord::Migration
  def self.up
    add_column :match_me_answers, :game, :string, :length => 16
    update("update match_me_answers set game = 'match_me'")
    add_index :match_me_answers, :game
  end

  def self.down
    remove_column :match_me_answers, :game
    remove_index :match_me_answers, :game
  end
end
