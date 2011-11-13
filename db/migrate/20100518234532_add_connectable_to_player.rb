class AddConnectableToPlayer < ActiveRecord::Migration
  def self.up
    add_column :players, :connectable, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :players, :connectable
  end
end
