class AddPlayerToAnswers < ActiveRecord::Migration
  def self.up
    change_table :answers do |t|
      t.integer   :player_id
    end

    add_index :answers, :player_id
    update("update answers set player_id = games.player_id from games where answers.game_id = games.id")
  end

  def self.down
    change_table :answers do |t|
      t.remove  :player_id
    end
  end
end
