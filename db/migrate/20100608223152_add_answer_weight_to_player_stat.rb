class AddAnswerWeightToPlayerStat < ActiveRecord::Migration
  def self.up
    add_column :player_stats, :answer_weight, :decimal, :precision => 5, :scale => 3
  end

  def self.down
    remove_column :player_stats, :answer_weight
  end
end
