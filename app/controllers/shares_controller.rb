class SharesController < ApplicationController

  def new
    default_message = <<-text
Hey,

I just discovered this new site, The Matching Game. It's the most amazing thing I've ever seen in my life.

If you don't check it out you may regret it for the rest of your life.

I'm serious. Drop everything now and go check it out.

Best,
#{@current_player.first_name}
    text
    @share = Share.new(:from => @current_player.full_name, :message => default_message)
  end

  def create
    Share.create({:player => @current_player}.merge(params[:share]))
    flash[:notice]= "Thanks for helping to spread the word!"
    redirect_to account_path
  end

end
