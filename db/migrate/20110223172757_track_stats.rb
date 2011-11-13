class TrackStats < ActiveRecord::Migration
  def self.up
    change_table :players do |t|
      t.integer   :pages_visited, :default => 0, :null => false
    end

    change_table :users do |t|
      t.integer  :emails_sent, :default => 0, :null => false
      t.datetime :last_emailed_at
    end
  end

  def self.down
    change_table :players do |t|
      t.remove  :pages_visited
    end

    change_table :users do |t|
      t.remove   :emails_sent
      t.remove   :last_emailed_at
    end
  end
end


__END__

Player
  pages visited
  last good match
  last good-good match
  last connection
  last message

User
  emails sent
  last emailed
