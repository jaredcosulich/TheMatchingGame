class AddWantPayments < ActiveRecord::Migration
  def self.up
    create_table :want_payments do |t|
      t.integer :user_id
      t.integer :amount
      t.integer :percent_to_charity
      t.string  :charity_name
      t.string  :charity_website
      t.string  :customer_id
      t.string  :charge_id

      t.timestamps
    end

    change_table :users do |t|
      t.date    :last_payment
    end
  end

  def self.down
    drop_table :want_payments
    change_table :users do |t|
      t.remove  :last_payment
    end
  end
end
