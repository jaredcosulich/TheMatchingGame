class CreateHelpResponses < ActiveRecord::Migration
  def self.up
    create_table :help_responses do |t|
      t.integer :player_id
      t.string :code
      t.text :feedback

      t.timestamps
    end
  end

  def self.down
    drop_table :help_responses
  end
end
