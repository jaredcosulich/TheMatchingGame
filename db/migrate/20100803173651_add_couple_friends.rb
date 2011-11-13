class AddCoupleFriends < ActiveRecord::Migration
  def self.up

    create_table :couple_friends do |t|
      t.integer :combo_id
      t.integer :other_combo_id
      t.timestamps
    end

  end

  def self.down
    drop_table :couple_friends
  end
end
