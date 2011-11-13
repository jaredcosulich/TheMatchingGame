class TapjoyOffers < ActiveRecord::Migration
  def self.up
    create_table :tapjoy_offers do |t|
      t.integer :user_id
      t.integer :tapjoy_id
      t.integer :credits

      t.timestamps
    end
  end

  def self.down
    drop_table :tapjoy_offers
  end
end
