class AddTos < ActiveRecord::Migration
  def self.up
    add_column :users, :terms_of_service, :boolean, :default => false
    update("update users set terms_of_service = true")
  end

  def self.down
    remove_column :users, :terms_of_service
  end
end
