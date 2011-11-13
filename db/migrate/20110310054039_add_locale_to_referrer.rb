class AddLocaleToReferrer < ActiveRecord::Migration
  def self.up
    change_table :referrals do |t|
      t.string :locale
    end

  end

  def self.down
    change_table :referrals do |t|
      t.remove :locale
    end
  end
end
