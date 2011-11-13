class ChallengesController < ApplicationController
  before_filter :find_from_obfuscated, :only => [:show, :play, :accept, :remove_challenger]

  def index
    @challenges = @current_player.challenge_players.collect(&:challenge)
  end

  def show
    @ranked_players = @challenge.challenge_players.ranked.full
    @challenge_player = @ranked_players.detect {|cp|cp.player == @current_player}
    redirect_to root_path and return if @challenge_player.nil? && !@challenge.completed?
    @challenge_combo_combos = @challenge.combos.with_response.all
  end

  def play
    challenge_player = @challenge.challenge_player_for(@current_player)
    redirect_to challenges_path and return if challenge_player.nil?
    @game = challenge_player.game || challenge_player.create_game
    @game.player = @current_player if @game.player.nil?
    @challenge_combo_combos = @challenge.combos_with_predicted(@game)

    if @challenge_combo_combos.empty?
      flash[:notice] = "You've already completed this challenge."
      redirect_to challenge_path(@challenge)
    end
  end

  def new
    @challenge = Challenge.new(:creator => @current_player)

    if from_challenge = @current_player.challenges.find_by_id(Integer.unobfuscate(params[:from] || "1"))
      from_challenge.challenge_players.sort { |a,b| (b.player == @current_player ? 1 : -1) <=> (a.player == @current_player ? 1 : -1) }.each do |cp|
        @challenge.challenge_players.build(:email => cp.player.email || cp.email, :name => cp.player.full_name || cp.name)
      end
    else
      @challenge.challenge_players.build(:email => @current_player.email, :name => @current_player.full_name)
    end

    @challenge.challenge_players.build
  end
  

  def create
    params[:challenge][:challenge_players_attributes].delete_if { |key, value| value['email'].blank? }
    if params[:challenge][:challenge_players_attributes].length < 2
      flash[:notice] = "You must challenge at least one other person."
      redirect_to :action => :new
      return
    end
     
    @challenge = Challenge.create({:creator => @current_player}.merge(params[:challenge]))
    
    if @challenge.valid?
      redirect_to challenge_path(@challenge)
    else
      if @challenge.challenge_players.empty?
        @challenge.challenge_players.build(:email => @current_player.email, :name => @current_player.full_name)
      end
      @challenge.challenge_players.build
      render :action => :new
    end
  end

  def accept
    challenger = @challenge.challenge_players.find_by_token(params[:token])

    if challenger
      @current_player = challenger.find_or_create_player(@current_player)
      redirect_to challenge_path(@challenge)
    else
      redirect_to root_path
    end

  end

  def remove_challenger
    if @current_player == @challenge.creator
      challenger = @challenge.challenge_players.find_by_id(params[:challenge_player_id])
      challenger.destroy if challenger.present?
    end
    redirect_to challenge_path(@challenge)
  end

  private
  def find_from_obfuscated
    challenge_id = Integer.unobfuscate(params[:id])
    @challenge = Challenge.find(challenge_id, :include => :challenge_players)
  end
end
