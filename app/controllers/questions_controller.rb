class QuestionsController < ApplicationController
  before_filter :ensure_registered_user
  before_filter :set_tab

  def index
    @my_questions = Question.where("player_id = ?", @current_player.id)
    @my_answers = QuestionAnswer.where("question_answers.player_id = ?", @current_player.id).includes(:question)
    my_question_ids = (@my_questions + @my_answers.map(&:question)).map(&:id).join(",")
    @popular_questions = Question.popular.not_in(my_question_ids).limit(10)
    @recent_questions = Question.recent.not_in(my_question_ids).limit(10)
    @all_questions = Question.alphabetic.limit(10)
  end

  def show
    @question = Question.includes(:question_answers => :player).find_by_permalink(params[:id])
    @my_answer = @question.question_answers.detect { |a| a.player_id == @current_player.id }
    @opposite_sex_answers = @question.question_answers.select { |a| a.player.gender != @current_player.gender }
  end

  def new
  end

  def create
    question = @current_player.questions.create(params[:question])
    redirect_to question_path(question)
  end

  def player
    @player = Player.includes(:interests, :question_answers => :question).find(Integer.unobfuscate(params[:id]))
  end

  private
  def set_tab
    @selected_tab = "labs"
    @selected_subtab = "questions"
  end

end
