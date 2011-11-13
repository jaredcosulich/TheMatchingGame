class AddExternalRefIdToTransaction < ActiveRecord::Migration
  def self.up
    add_column :transactions, :external_ref_id, :string
    add_index :transactions, [:external_ref_id], :unique => true
  end

  def self.down
    remove_column :transactions, :external_ref_id
  end
end
