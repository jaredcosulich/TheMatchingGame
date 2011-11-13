class RemoveRealLifeCombos < ActiveRecord::Migration
  def self.up
    drop_table :real_life_combos
  end

  def self.down
    create_table :real_life_combos do |t|
      t.timestamps
    end
  end
end
