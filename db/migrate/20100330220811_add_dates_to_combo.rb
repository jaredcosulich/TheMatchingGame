class AddDatesToCombo < ActiveRecord::Migration
  def self.up
    change_table :combos do |t|
      t.date :matched_on
      t.date :married_on
    end
  end

  def self.down
    change_table :combos do |t|
      t.remove :matched_on
      t.remove :married_on
    end
  end
end
