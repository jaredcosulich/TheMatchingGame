class MakePhotoUserIdIntNotNull < ActiveRecord::Migration
  def self.up
    add_column :photos, :int_user_id, :integer, :null => true
    execute("update photos set int_user_id = to_number(user_id, '99999')")
    change_column :photos, :int_user_id, :integer, :null => false

    remove_column :photos, :user_id
    rename_column :photos, :int_user_id, :user_id
  end

  def self.down
    change_column :photos, :user_id, :string, :length => 1
  end
end
