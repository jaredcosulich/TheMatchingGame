class AddInterests < ActiveRecord::Migration
  def self.up
    create_table :interests, :force => true do |t|
      t.integer :player_id
      t.string :title
    end
  end

  def self.down
    drop_table :interests
  end
end
