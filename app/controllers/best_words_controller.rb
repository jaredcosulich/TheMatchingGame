class BestWordsController < ApplicationController

  def index
  end

  def create
    AdminMailer.delay(:priority => 9).deliver_notify("BestWords Submitted", "Slug: #{params[:player][:best_words_slug]}", :player => @current_player)

    if Player.check_slug(params[:player][:best_words_slug])
      @current_player.update_attributes(params[:player])
    else
      flash[:notice] = "Please have more people fill out your BestWords.Me page.<br/><br/>If you think this is in error please let me know using the support link at the bottom of the page.".html_safe
    end
    redirect_to best_words_path
  end

end
