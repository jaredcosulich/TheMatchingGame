class AddScoresToPhotoPair < ActiveRecord::Migration
  def self.up
    change_table :photo_pairs do |t|
      t.decimal :connection_score
      t.decimal :correlation_score
    end
    execute("update photo_pairs set connection_score = calc_connection_score(photo_pairs.*)")
  end

  def self.down
    change_table :photo_pairs do |t|
      t.remove :connection_score
      t.remove :correlation_score
    end
  end
end
