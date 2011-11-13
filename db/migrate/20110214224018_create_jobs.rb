class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :crowdflower_jobs do |t|
      t.integer :user_id
      t.integer :job_id
      t.string :job_title
      t.string :conversion_id
      t.integer :amount
      t.integer :adjusted_amount
      t.text :initiate_payload
      t.text :complete_payload
      t.datetime :completed_at

      t.timestamps
    end
    add_index :crowdflower_jobs, :user_id
    add_index :crowdflower_jobs, :conversion_id
  end

  def self.down
    drop_table :crowdflower_jobs
  end
end
