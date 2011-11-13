class CreateScoreEvents < ActiveRecord::Migration
  def self.up
    create_table :score_events do |t|
      t.integer   :player_id
      t.string    :type
      t.integer   :event_id
      t.string    :event_type
      t.timestamp :event_at
      t.integer   :answer_count
      t.integer   :correct_count
      t.integer   :incorrect_count
      t.integer   :score

      t.timestamps
    end
  end

  def self.down
    drop_table :score_events
  end
end
