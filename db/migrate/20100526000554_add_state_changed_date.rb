class AddStateChangedDate < ActiveRecord::Migration
  def self.up
    add_column :combos, :state_changed_at, :datetime
    add_column :answers, :viewed_at, :datetime

    execute("update combos set state_changed_at = inactivated_at;")
    execute("UPDATE combos set state_changed_at = responses.updated_at from responses where responses.combo_id = combos.id;")
    execute("UPDATE answers set viewed_at = '#{1.day.ago}';")    
  end

  def self.down
    remove_column :combos, :state_changed_at
    remove_column :answers, :viewed_at
  end
end
