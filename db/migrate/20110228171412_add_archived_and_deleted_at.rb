class AddArchivedAndDeletedAt < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.datetime   :deleted_at
      t.text       :deleted_reason
    end

    change_table :combos do |t|
      t.datetime   :archived_at
    end
  end

  def self.down
    change_table :users do |t|
      t.remove    :deleted_at
      t.remove    :deleted_reason
    end

    change_table :combos do |t|
      t.remove    :archived_at
    end
  end
end
