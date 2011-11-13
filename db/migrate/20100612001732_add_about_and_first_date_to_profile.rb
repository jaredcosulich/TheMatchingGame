class AddAboutAndFirstDateToProfile < ActiveRecord::Migration
  def self.up
    add_column :profiles, :about, :text
    add_column :profiles, :first_date, :text
  end

  def self.down
    remove_column :profiles, :about
    remove_column :profiles, :first_date
  end
end
