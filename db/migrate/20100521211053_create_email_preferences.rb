class CreateEmailPreferences < ActiveRecord::Migration
  def self.up
    create_table :email_preferences do |t|
      t.integer :user_id
      t.boolean :awaiting_response, :default => true, :null => false
      t.boolean :prediction_progress, :default => true, :null => false
      t.timestamps
    end

    execute("insert into email_preferences (select id, id, true, true from users)")
    execute("select setval('email_preferences_id_seq', (select max(id) from email_preferences))")

  end

  def self.down
    drop_table :email_preferences
  end
end
