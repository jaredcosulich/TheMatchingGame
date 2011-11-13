class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :fb_id

      t.timestamps
    end

    remove_column :games, :fb_id
    add_column :games, :user_id, :integer
  end

  def self.down
    drop_table :users

    add_column :games, :fb_id, :string
    remove_column :games, :user_id
  end
end
