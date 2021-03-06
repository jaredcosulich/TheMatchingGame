class TrackEmailsAndLinks < ActiveRecord::Migration
  def self.up
    create_table :emailings do |t|
      t.integer :user_id
      t.string :email_name
      t.text :body
      t.timestamps
    end

    create_table :links do |t|
      t.string :source_type
      t.integer :source_id
      t.string :path
      t.timestamps
    end

    create_table :link_clicks do |t|
      t.integer :link_id
      t.timestamps
    end
  end

  def self.down
    drop_table :link_clicks
    drop_table :links
    drop_table :emailings
  end
end
