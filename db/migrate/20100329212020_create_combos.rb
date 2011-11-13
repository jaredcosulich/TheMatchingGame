class CreateCombos < ActiveRecord::Migration
  def self.up
    create_table :combos do |t|
      t.integer :photo_one_id, :null => false
      t.integer :photo_two_id, :null => false
      t.integer :yes_count, :default => 0
      t.integer :no_count, :default => 0
      t.integer :yes_percent, :default => 0
    end
  end

  def self.down
    drop_table :combos
  end
end
