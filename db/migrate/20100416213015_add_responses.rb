class AddResponses < ActiveRecord::Migration
  def self.up
    create_table :responses do |m|
      m.integer :combo_id, :null => false
      m.string :photo_one_answer, :length => 1
      m.string :photo_two_answer, :length => 1
      m.string :photo_one_connect, :length => 1
      m.string :photo_two_connect, :length => 1
    end

  end

  def self.down
    drop_table :responses
  end

end
