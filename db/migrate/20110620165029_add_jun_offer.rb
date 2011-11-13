class AddJunOffer < ActiveRecord::Migration
  def self.up
    create_table :jun_offers do |t|
      t.integer :user_id
      t.integer :credits

      t.timestamps
    end
  end

  def self.down
    drop_table :jun_offers
  end
end
