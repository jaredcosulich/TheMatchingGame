class ChangeResponsesToOneAnswerPerUser < ActiveRecord::Migration
  def self.up
    change_table :responses do |r|
      r.remove :photo_one_connect, :photo_two_connect
      r.change :photo_one_answer, :string
      r.change :photo_two_answer, :string
    end
  end

  def self.down
    change_table :responses do |r|
      r.string :photo_one_connect
      r.string :photo_two_connect
    end
  end
end
