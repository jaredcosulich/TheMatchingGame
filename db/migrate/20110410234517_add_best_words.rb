class AddBestWords < ActiveRecord::Migration
  def self.up
    change_table :players do |t|
      t.string :best_words_slug
    end
  end

  def self.down
    change_table :players do |t|
      t.remove :best_words_slug
    end
  end
end
