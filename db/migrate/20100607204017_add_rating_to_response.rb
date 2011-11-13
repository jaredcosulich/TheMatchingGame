class AddRatingToResponse < ActiveRecord::Migration
  def self.up
    add_column :responses, :photo_one_rating, :integer
    add_column :responses, :photo_two_rating, :integer
  end

  def self.down
    remove_column :responses, :photo_one_rating
    remove_column :responses, :photo_two_rating
  end
end
