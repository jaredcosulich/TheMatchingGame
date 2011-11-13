class AddIndexesToMatchMeGame < ActiveRecord::Migration
  def self.up
    add_index :match_me_answers, :other_photo_id
    add_index :match_me_answers, [:target_photo_id, :other_photo_id]
  end

  def self.down
    remove_index :match_me_answers, [:target_photo_id, :other_photo_id]
    remove_index :match_me_answers, :other_photo_id
  end
end
