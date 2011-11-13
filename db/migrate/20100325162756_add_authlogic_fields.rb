class AddAuthlogicFields < ActiveRecord::Migration
  def self.up
    change_table :users do |t|

      t.string :email

      #authlogic fields
      t.string :crypted_password
      t.string :password_salt
      t.string :persistence_token
      t.integer :login_count, :default => 0, :null => false
      t.datetime :last_request_at
      t.datetime :last_login_at
      t.datetime :current_login_at
      t.string :last_login_ip
      t.string :current_login_ip
    end
  end

  def self.down
    change_table :users do |t|

      t.remove :email

      #authlogic fields
      t.remove :crypted_password
      t.remove :password_salt
      t.remove :persistence_token
      t.remove :login_count, :default => 0, :null => false
      t.remove :last_request_at
      t.remove :last_login_at
      t.remove :current_login_at
      t.remove :last_login_ip
      t.remove :current_login_ip
    end
  end
end
