class AddUserToPhoto < ActiveRecord::Migration
  def self.up
    change_table :photos do |t|
      t.column :user_id, :integer
      t.column :approved, :boolean, :default => false
    end
  end

  def self.down
    change_table :photos do |t|
      t.remove :user_id
      t.remove :approved
    end
  end
end
