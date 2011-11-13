class CreateComboScore < ActiveRecord::Migration
  def self.up
    create_table :combo_scores do |t|
      t.integer :combo_id
      t.integer :photo_id
      t.integer :yes_count
      t.integer :no_count
      t.integer :vote_count
      t.integer :yes_percent
      t.boolean :active
      t.integer :response
      t.integer :other_photo_id
      t.boolean :other_photo_approved
      t.integer :other_response
      t.integer :score
    end
    add_index :combo_scores, [:combo_id, :photo_id], :unique => true
  end

  def self.down
    drop_table :combo_scores
  end
end
