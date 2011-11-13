class TimestampsOnInterests < ActiveRecord::Migration
  def self.up
    change_table :interests do |t|
      t.timestamps
    end

    update("update interests set created_at = players.created_at from players where players.id = interests.player_id")
  end

  def self.down
  end
end
