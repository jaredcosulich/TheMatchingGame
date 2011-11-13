class ResponseGenerationChanges < ActiveRecord::Migration
  def self.up
    change_table :responses do |t|
      t.string   :creation_reason, :limit => 16
      t.datetime :revealed_at
    end
    update("update responses set revealed_at = inactivated_at from combos where combo_id = combos.id")
  end

  def self.down
    change_table :responses do |t|
      t.remove   :creation_reason
      t.remove :revealed_at
    end

  end
end
