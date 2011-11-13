class AddCompletedAtAndCorrectCountToChallengePlayer < ActiveRecord::Migration
  def self.up
    add_column :challenge_players, :completed_at, :datetime
    add_column :challenge_players, :correct_count, :integer, :default => 0
  end

  def self.down
    remove_column :challenge_players, :correct_count
    remove_column :challenge_players, :completed_at
  end
end
