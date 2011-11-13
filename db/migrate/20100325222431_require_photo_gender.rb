class RequirePhotoGender < ActiveRecord::Migration
  def self.up
    execute("update photos set gender = 'm' where gender is null")
    change_column :photos, :gender, :string, :length => 1, :null => false
  end

  def self.down
    change_column :photos, :gender, :string, :length => 1
  end
end
