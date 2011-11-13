class CreateFacebookProfiles < ActiveRecord::Migration
  def self.up
    create_table :facebook_profiles do |t|
      t.integer :player_id
      t.text :fb_info

      t.timestamps
    end

    add_column :players, :preferred_profile_type, :string
    add_column :players, :preferred_profile_id, :integer
  end

  def self.down
    drop_table :facebook_profiles

    remove_column :players, :preferred_profile_type
    remove_column :players, :preferred_profile_id
  end
end
