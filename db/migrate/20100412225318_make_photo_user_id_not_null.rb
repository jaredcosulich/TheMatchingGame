class MakePhotoUserIdNotNull < ActiveRecord::Migration
  def self.up
    execute("update photos set user_id = 1 where user_id is null")
    change_column :photos, :user_id, :string, :length => 1, :null => false
  end

  def self.down
    change_column :photos, :user_id, :string, :length => 1
  end
end
