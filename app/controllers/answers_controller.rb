class AnswersController < ApplicationController
  
  def show
    @answers = @current_player.answer_groups
    @counts = @current_player.answer_counts
    Answer.set_viewed_at(@answers) unless @answers.empty?
  end

  def query
    answers = @current_player.answer_groups(params[:q], params[:offset])
    Answer.set_viewed_at(answers) unless answers.empty?
    render :partial => "answers/answer", :collection => answers
  end

end
