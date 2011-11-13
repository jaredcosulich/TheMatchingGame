require 'spec_helper'

describe ScoreEvent do
  before :each do
    @player = Factory.create :player

    @good_training_combo = Factory.create(:response, :photo_one_answer => "good", :photo_two_answer => "good").combo
    @bad_training_combo = Factory.create(:response, :photo_one_answer => "bad").combo
    @predicting_combo = Factory.create(:combo)

    @game_one = Factory.create(:game, :player => @player)
    Factory.create(:answer, :game => @game_one, :combo => @good_training_combo, :answer => "y")
    @predicting_answer = Factory.create(:answer, :game => @game_one, :combo => @predicting_combo, :answer => "y")

    @game_two = Factory.create(:game, :player => @player)
    Factory.create(:answer, :game => @game_two, :combo => @bad_training_combo, :answer => "y")

    @bad_response = Factory.create(:response, :combo => @predicting_combo, :photo_one_answer => "bad")

    @game_three = Factory.create(:game, :player => @player)
    Factory.create(:answer, :game => @game_three, :answer => "n")

  end

  it "should record a game" do
    game_event = GameEvent.new(@game_one)

    game_event.answer_count.should == 2
    game_event.correct_count.should == 1
    game_event.incorrect_count.should == 0
    game_event.event_at.should == @game_one.created_at
  end

  it "should record a response" do
    @predicting_answer.reload
    game_event = ResponseEvent.new(@bad_response, @predicting_answer)

    game_event.answer_count.should == 0
    game_event.correct_count.should == 0
    game_event.incorrect_count.should == 1
    game_event.event_at.should == @bad_response.photo_one_answered_at
  end

end
