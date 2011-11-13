class AddQuestionsAndAnswers < ActiveRecord::Migration
  def self.up
    create_table :questions do |t|
      t.integer   :player_id, :nil => false
      t.string    :title
      t.string    :permalink
      t.boolean   :long_answers, :nil => false, :default => false
      t.boolean   :verified, :nil => false, :default => false
      t.string    :suggested_answers

      t.timestamps
    end

    create_table :question_answers do |t|
      t.integer   :question_id, :nil => false
      t.integer   :player_id, :nil => false
      t.text      :answer

      t.timestamps
    end
  end

  def self.down
    drop_table :questions
    drop_table :question_answers
  end
end
