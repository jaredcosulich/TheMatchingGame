class SwitchingToNoRegistration < ActiveRecord::Migration
  def self.up
    add_column :profiles, :player_id, :integer
    add_column :photos, :player_id, :integer

    update("update photos set player_id = 0 where user_id = 0")
    update("update profiles set (player_id) = (u.player_id) FROM users u WHERE profiles.user_id = u.id")
    update("update photos set (player_id) = (u.player_id) FROM users u WHERE photos.user_id = u.id")

    change_column :profiles, :player_id, :integer, :null => false
    change_column :photos, :player_id, :integer, :null => false

    remove_column :profiles, :user_id
    remove_column :photos, :user_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
