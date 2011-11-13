require 'spec_helper'

describe GameObserver do
  it "should create a GameEvent on create" do
    ActiveRecord::Observer.with_observers(:game_observer) do
      player = Factory.create(:player)
      game = Factory.create(:game, :player => player)
      event = player.score_events.only
      event.event.should == game
      event.answer_count.should == 0
      event.correct_count.should == 0
      event.incorrect_count.should == 0
    end
  end

  it "should update the GameEvent as answers are added to the game" do
    ActiveRecord::Observer.with_observers(:game_observer) do
      player = Factory.create(:player)
      game = Factory.create(:game, :player => player)
      yes_combo = Factory.create(:response, :photo_one_answer => "good", :photo_two_answer => "good").combo
      Factory.create(:answer, :game => game, "answer" => "y", :combo => yes_combo)
      event = player.score_events.only
      event.answer_count.should == 1
      event.correct_count.should == 1
      event.incorrect_count.should == 0

    end
  end

  it "should call check completed on the game when an answer is created" do
    player = Factory.create(:player)
    ActiveRecord::Observer.with_observers(:game_observer) do
      game = Factory.create(:game, :player => player)
      game.should_receive(:check_completed)
      Factory.create(:answer, :game => game, "answer" => "y")
    end
  end
end
