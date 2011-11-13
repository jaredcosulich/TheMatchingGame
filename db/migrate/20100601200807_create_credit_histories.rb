class CreateCreditHistories < ActiveRecord::Migration
  def self.up
    create_table :credit_histories do |t|
      t.integer :user_id
      t.integer :amount
      t.integer :net_payout_amount
      t.string  :premium_currency_label
      t.integer :premium_currency_amount
      t.string  :offer_id
      t.integer :offer_amount
      t.string  :offer_amount_iso_currency_code
      t.string  :pegged_currency_label
      t.integer :pegged_currency_amount
      t.string  :pegged_currency_amount_iso_currency_code
      t.integer :user_balance
      t.string  :socialgold_transaction_id
      t.string  :external_ref_id
      t.string  :socialgold_transaction_status
      t.string  :event_type
      t.string  :version
      t.text    :extra_fields
      t.timestamps
    end

    add_column :users, :credits, :integer
  end

  def self.down
    drop_table :credit_histories
    remove_column :users, :credits
  end
end
