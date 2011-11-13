class SplitPlayerAndUser < ActiveRecord::Migration
  def self.up
    create_table :players do |p|
      p.string   "gender", :limit => 1
    end

    execute("insert into players (select id, gender from users)")
    execute("select setval('players_id_seq', (select max(id) from players))")

    change_table :users do |u|
      u.column :player_id, :integer
      u.remove :gender
    end

    execute("update users set player_id = id;")

    rename_column :games, :user_id, :player_id

    change_column :users, :player_id, :integer, :null => false
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
