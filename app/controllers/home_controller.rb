class HomeController < ApplicationController

  def index
    @game = Game.new(:player => @current_player)
    if params[:c].blank?
      combo_count = Features.combos_to_show
    elsif params[:c] == 'e'
      combo_count = 20
    else
      combo_count = params[:c].to_i
    end

    @combos = @game.combos(combo_count > 50 ? 50 : combo_count)

#    @my_good_introductions = @current_player.answers.good_introductions.find(:all, :limit => 2).map(&:combo)
#    @my_good_introduction_count = @current_player.answers.good_introductions.count
#    @my_bad_introductions = @current_player.answers.bad_introductions.find(:all, :limit => 2).map(&:combo)
#    @my_bad_introduction_count = @current_player.answers.bad_introductions.count
#    @my_potential_introductions = @current_player.answers.potential_introductions.find(:all, :limit => 2).map(&:combo)
#    @my_potential_introduction_count = @current_player.answers.potential_introductions.count
  end

  def safari
    @current_player.save
    redirect_to root_path
  end

  def show_user_voice
    false
  end

  def spread_the_word
  end

  def close
    render :layout => false
  end

  def feedback
    if params[:feedback].blank? || params[:feedback][:message] =~ /\[url=/
      render :nothing => true and return
    end

    AdminMailer.delay(:priority => 9).deliver_notify("The Matching Game Feedback from #{@current_player.user.nil? ? 'anonymous' : @current_player.user.email}",
                         params[:feedback][:message],
                         {:email => params[:feedback][:email], :current_user => @current_player.user})
    render :nothing => true
  end
end
