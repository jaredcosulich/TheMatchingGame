class CreateShares < ActiveRecord::Migration
  def self.up
    create_table :shares do |t|
      t.integer :player_id
      t.string :from
      t.string :type
      t.text :fb_ids
      t.text :emails
      t.text :message
      t.string :status

      t.timestamps
    end
  end

  def self.down
    drop_table :shares
  end
end
