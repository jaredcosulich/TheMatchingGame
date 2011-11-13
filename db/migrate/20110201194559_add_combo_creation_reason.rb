class AddComboCreationReason < ActiveRecord::Migration
  def self.up
    add_column :combos, :creation_reason, :string, :length => 16
    update("update combos set creation_reason = 'legacy'")
  end

  def self.down
    remove_column :combos, :creation_reason
  end
end
