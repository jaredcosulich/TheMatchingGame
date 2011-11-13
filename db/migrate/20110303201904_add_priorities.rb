class AddPriorities < ActiveRecord::Migration
  def self.up
    create_table :priorities do |t|
      t.integer :photo_id
      t.integer :user_id
      t.integer :credits_applied
      t.integer :days_purchased

      t.timestamps
    end

    change_table :photos do |t|
      t.datetime   :priority_until
    end
    add_index :photos, :priority_until
  end

  def self.down
    drop_table :priorities

    change_table :photos do |t|
      t.remove    :priority_until
    end

  end
end
