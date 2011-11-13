require 'spec_helper'

describe GameAnswersController do

  describe "create" do
    it "should create an answer that connects two photos" do
      game = Factory.create(:game)
      photo_1 = Factory.create(:male_photo)
      photo_2 = Factory.create(:female_photo)
      combo = Factory.create(:combo, :photo_one => photo_1, :photo_two => photo_2)
      post :create, :game_id => game.to_param, :answer => {
        :combo_id => combo.id,
        :answer => "y"
      }
      response.should be_success

      answer = game.answers.only
      answer.combo.should == combo
      answer.answer.should == "y"
    end

    it "should not save the answer if it is a coupled combo that has the max votes" do
      game = Factory.create(:game)
      photo_1 = Factory.create(:male_photo)
      photo_2 = Factory.create(:female_photo)
      couple_combo = Factory.create(:combo, :photo_one => photo_1, :photo_two => photo_2)
      photo_1.update_attribute(:couple_combo, couple_combo)
      photo_2.update_attribute(:couple_combo, couple_combo)
      Features.coupled_vote_count.times { |i| Factory.create(:answer, :combo => couple_combo) }
      Answer.count.should == Features.coupled_vote_count

      post :create, :game_id => game.to_param, :answer => {
        :combo_id => couple_combo.id,
        :answer => "y"
      }
      response.should be_success

      game.answers.should be_empty
      Answer.count.should == Features.coupled_vote_count
    end

    it "should create a badge if one is specified" do
      player = Factory.create(:registered_player)
      set_session_for_player(player)
      game = Factory.create(:game)
      photo_1 = Factory.create(:male_photo)
      photo_2 = Factory.create(:female_photo)
      badge = Badge.create(:icon => "a_badge", :name => "A Badge")
      combo = Factory.create(:combo, :photo_one => photo_1, :photo_two => photo_2)
      post :create, :game_id => game.to_param, :answer => {
        :combo_id => combo.id,
        :answer => "y"
      },
      :badge => "a_badge"
      response.should be_success

      answer = game.answers.only
      answer.combo.should == combo
      answer.answer.should == "y"

      player.reload.badges.only.should == badge
    end

  end

end
