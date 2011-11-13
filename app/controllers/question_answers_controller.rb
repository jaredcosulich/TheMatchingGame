class QuestionAnswersController < ApplicationController

  def create
    @question = Question.find_by_permalink(params[:question_id])
    if (answer = @question.question_answers.where("player_id = ?", @current_player.id).first).nil?
      @question.question_answers.create(params[:question_answer].merge(:player => @current_player))
    else
      answer.update_attributes(params[:question_answer])
    end
    redirect_to question_path(@question)
  end

end
