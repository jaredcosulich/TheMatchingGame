class AddClubs < ActiveRecord::Migration
  def self.up
    create_table :clubs do |t|
      t.string    :title
      t.string    :permalink
      t.integer   :interests_count, :nil => false, :default => 0
      t.boolean   :verified

      t.timestamps
    end

    change_table :interests do |t|
      t.integer   :club_id
    end
    add_index :interests, :club_id
  end

  def self.down
    drop_table :clubs

    change_table :interests do |t|
      t.remove  :club_id
    end
  end
end
