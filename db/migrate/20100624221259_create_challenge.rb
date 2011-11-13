class CreateChallenge < ActiveRecord::Migration
  def self.up
    create_table :challenges do |t|
      t.integer :creator_id
      t.string :name
      t.text :invitation_text
      t.timestamps
    end

    create_table :challenge_players do |t|
      t.integer :challenge_id
      t.integer :player_id
      t.integer :score
      t.string :email
      t.string :fb_id
      t.string :name
      t.string :token
      t.timestamps
    end

    create_table :challenge_combos do |t|
      t.integer :challenge_id
      t.integer :combo_id

      t.timestamps
    end

    add_column :games, :challenge_player_id, :integer
    add_column :answers, :kind, :string
    execute("update answers set kind = 'predicted'")
    execute("update answers set kind = 'existed' from responses, combos where answers.combo_id = combos.id and combos.id = responses.combo_id AND answers.created_at > responses.created_at")
  end

  def self.down
    remove_column :answers, :kind
    remove_column :games, :challenge_player_id
    drop_table :challenge_combos
    drop_table :challenge_players
    drop_table :challenges
  end
end
