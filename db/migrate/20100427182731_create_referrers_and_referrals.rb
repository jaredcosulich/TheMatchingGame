class CreateReferrersAndReferrals < ActiveRecord::Migration
  def self.up
    create_table :referrers do |t|
      t.string :url
      t.string :uid
      t.string :title
      t.string :note

      t.timestamps
    end
    create_table :referrals do |t|
      t.integer :referrer_id
      t.integer :player_id
      t.timestamps
    end
  end

  def self.down
    drop_table :referrers
    drop_table :referrals
  end
end
