class AddCollege < ActiveRecord::Migration
  def self.up
    change_table :players do |t|
      t.boolean :same_sex, :nil => false, :default => false
      t.integer :college_id
    end

    change_table :photos do |t|
      t.boolean :same_sex, :nil => false, :default => false
      t.integer :college_id
    end

    change_table :photo_pairs do |t|
      t.integer :college_id
    end

    change_table :combos do |t|
      t.integer :college_id
    end

    create_table :colleges do |t|
      t.string :name
      t.string :fb_id
      t.boolean :verified, :nil => false, :default => false
    end
  end

  def self.down
    change_table :players do |t|
      t.remove :same_sex
      t.remove :college_id
    end

    change_table :photos do |t|
      t.remove :same_sex
      t.remove :college_id
    end

    change_table :photo_pairs do |t|
      t.remove :college_id
    end

    change_table :combos do |t|
      t.remove :college_id
    end

    drop_table :colleges
  end
end
