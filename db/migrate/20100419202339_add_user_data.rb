class AddUserData < ActiveRecord::Migration
  def self.up
    change_table :users do |u|
      u.date :birthdate
      u.string :sexual_orientation, :length => 1
      u.string :first_name
      u.string :last_name
      u.string :location_name
      u.decimal :location_lat, :precision => 9, :scale => 6
      u.decimal :location_lng, :precision => 9, :scale => 6
    end
  end

  def self.down
    change_table :users do |u|
      u.remove :birthdate
      u.remove :sexual_orientation
      u.remove :first_name
      u.remove :last_name
      u.remove :location_name
      u.remove :location_lat
      u.remove :location_lng
    end
  end
end
