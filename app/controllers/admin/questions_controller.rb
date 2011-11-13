class Admin::QuestionsController < AdminController

  def index
    @unverified_questions = Question.unverified.limit(10)
    @recent_questions = Question.recent.limit(10)
  end

  def create
    Question.create(params[:question].merge(:verified => true))
    redirect_to admin_questions_path
  end

end
