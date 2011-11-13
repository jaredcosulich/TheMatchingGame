class LinkAnswerToCombo < ActiveRecord::Migration
  def self.up
    change_table :answers do |t|
      t.integer :combo_id
      t.remove :left_photo_id
      t.remove :right_photo_id
    end
  end

  def self.down
    change_table :answers do |t|
      t.remove :combo_id
      t.integer :left_photo_id
      t.integer :right_photo_id
    end    
  end
end
