class CreateComboActions < ActiveRecord::Migration
  def self.up
    create_table :combo_actions do |t|
      t.integer :combo_id, :null => false
      t.integer :photo_id, :null => false
      t.string :action, :null => false
      t.text :message

      t.timestamp :viewed_at
      t.timestamps
    end

    create_table :transactions do |t|
      t.integer  :user_id
      t.integer :source_id
      t.string :source_type
      t.integer :amount
      t.timestamps
    end

    rename_table :credit_histories, :social_gold_transactions
  end

  def self.down
    rename_table :social_gold_transactions, :credit_histories
    drop_table :transactions

    drop_table :combo_actions
  end
end
