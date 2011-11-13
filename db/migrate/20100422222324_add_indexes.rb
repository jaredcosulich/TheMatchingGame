class AddIndexes < ActiveRecord::Migration
  def self.up
    delete("delete from users where fb_id is null")
    add_index :users, :email, :unique => true 
  end

  def self.down
    remove_index :users, :email
  end
end
