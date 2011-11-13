class AddBadges < ActiveRecord::Migration
  def self.up
    create_table :player_badges do |t|
      t.integer :player_id
      t.integer :badge_id
      t.timestamps
    end

    create_table :badges do |t|
      t.string  :name
      t.string  :description
      t.string  :icon
      t.timestamps
    end

    Badge.create(:name => "Lucky Streak", :icon => "5_streak_badge")
    Badge.create(:name => "Super Lucky Streak", :icon => "10_streak_badge")
    Badge.create(:name => "Super Duper Lucky Streak", :icon => "20_streak_badge")
    Badge.create(:name => "Somewhat Suspicious Super Duper Lucky Streak", :icon => "50_streak_badge")
  end

  def self.down
    drop_table :player_badges
    drop_table :badges
  end
end
