class CreateGames < ActiveRecord::Migration
  def self.up
    create_table :games do |t|
      t.string :fb_id

      t.timestamps
    end
    add_index :games, :fb_id
  end

  def self.down
    drop_table :games
  end
end
