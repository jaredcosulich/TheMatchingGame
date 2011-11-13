class AddRealLifeCombos < ActiveRecord::Migration
  def self.up
    create_table :real_life_combos do |t|
      t.integer :combo_id
      t.date :coupled_on
      t.date :married_on
    end

    execute("INSERT INTO real_life_combos (combo_id, married_on) (select id, married_on from combos where married_on is not null)")

    remove_column :combos, :married_on
    remove_column :combos, :matched_on
  end

  def self.down
    add_column :combos, :married_on, :date
    add_column :combos, :matched_on, :date

    execute("UPDATE combos set married_on = real_life_combos.married_on from real_life_combos where real_life_combos.combo_id = combos.id")

    drop_table :real_life_combos
  end
end
