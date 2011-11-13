class AddStateToPhotos < ActiveRecord::Migration
  def self.up
    add_column :photos, :current_state, :string, :null => false, :default => "unconfirmed"
    add_column :photos, :rejected_reason, :string

    update("update photos set current_state = 'approved' where approved = true")
    update("update photos set current_state = 'confirmed' where approved = false AND rejected = false")

    remove_column :photos, :approved
    remove_column :photos, :rejected
  end

  def self.down
    add_column :photos, :approved, :boolean, :default => false, :null => false
    add_column :photos, :rejected, :boolean, :default => false, :null => false

    update("update photos set approved = true where current_state = 'approved';")

    remove_column :photos, :current_state
    remove_column :photos, :rejected_reason
  end
end
