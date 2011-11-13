class CreateAnswers < ActiveRecord::Migration
  def self.up
    create_table :answers do |t|
      t.integer :game_id, :null => false
      t.integer :right_photo_id, :null => false
      t.integer :left_photo_id, :null => false
      t.string :answer, :null => false, :length => 1

      t.timestamps
    end
  end

  def self.down
    drop_table :answers
  end
end


