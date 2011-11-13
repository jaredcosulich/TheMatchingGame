class AddRespondedAtsToResponse < ActiveRecord::Migration
  def self.up
    change_table :responses do |t|
      t.datetime :photo_one_answered_at
      t.datetime :photo_two_answered_at
    end

    execute("update responses set photo_one_answered_at = updated_at where photo_one_answer is not null")
    execute("update responses set photo_two_answered_at = updated_at where photo_two_answer is not null")

  end

  def self.down
    remove_column :responses, :photo_one_answered_at
    remove_column :responses, :photo_two_answered_at
  end
end
