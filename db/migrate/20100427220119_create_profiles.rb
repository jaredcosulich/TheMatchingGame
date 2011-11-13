class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.integer :user_id
      t.string :first_name
      t.string :last_name
      t.string :location_name
      t.decimal  :location_lat, :precision => 9, :scale => 6
      t.decimal  :location_lng, :precision => 9, :scale => 6
      t.date :birthdate
      t.string :sexual_orientation, :length => 1

      t.timestamps
    end

    insert("INSERT INTO profiles (user_id,first_name, last_name, location_name, location_lat, location_lng, birthdate, sexual_orientation ) (select id, first_name, last_name, location_name, location_lat, location_lng, birthdate, sexual_orientation from  users)")

    change_table :users do |u|
      u.remove :first_name, :last_name
      u.remove :location_name, :location_lat, :location_lng
      u.remove :birthdate, :sexual_orientation
    end
  end

  def self.down
    change_table :users do |u|
      u.string :first_name
      u.string :last_name
      u.string :location_name
      u.decimal :location_lat, :precision => 9, :scale => 6
      u.decimal :location_lng, :precision => 9, :scale => 6
      u.date :birthdate
      u.string :sexual_orientation, :length => 1
    end

    update("update users set (first_name, last_name, location_name, location_lat, location_lng, birthdate, sexual_orientation) = (p.first_name, p.last_name, p.location_name, p.location_lat, p.location_lng, p.birthdate, p.sexual_orientation) FROM profiles p WHERE p.user_id = users.id")

    drop_table :profiles
  end
end
