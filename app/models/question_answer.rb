class QuestionAnswer < ActiveRecord::Base
  belongs_to :question
  belongs_to :player
end
