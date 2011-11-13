class AddLocationToPlayer < ActiveRecord::Migration
  def self.up
    change_table :players do |t|
      t.string :geo_name
      t.decimal :geo_lat, :precision => 9, :scale => 6
      t.decimal :geo_lng, :precision => 9, :scale => 6
    end
  end

  def self.down
    change_table :players do |t|
      t.remove :geo_name
      t.remove :geo_lat
      t.remove :geo_lng
    end
  end
end
