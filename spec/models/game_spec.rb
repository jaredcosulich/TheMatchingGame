require 'spec_helper'

describe Game do
  describe "new_combos" do
    before :each do
      @combos = (0...3).collect { Factory.create :combo }
      Factory.create :combo, :active => false
      @player = Factory.create(:player)
      @game = Factory.create(:game, :player => @player)
    end

    it "should provide up to N combos" do
      @game.combos(2).length.should == 2
      @game.combos(10).length.should == 3
    end

    it "should not choose combos you've already answered" do
      previous_game = Factory.create(:game, :player => @player)
      2.times { |i| Factory.create(:answer, :game => previous_game, :combo => @combos[i]) }
      @game.combos(10).should == [@combos[2]]
    end

    it "should not duplicate any photos in a game" do
      Factory.create(:combo, :photo_one => @combos[1].photo_two, :photo_two => Factory(:male_photo))
      game_combos = @game.combos(4)
      game_combos.length.should == 3
      game_combos.collect { |combo| [combo.photo_one_id, combo.photo_two_id] }.flatten.uniq.length.should == 6
    end

    it "should not show you any of your own photos" do
      @game = Factory.create(:game, :player => @combos.first.photo_one.player)
      @game.combos(10).length.should == 2      
      @game.combos(10).should_not include(@combos.first)
    end

    it "should not show you any photos of people you are already interested in" do
      Factory.create(:response, :combo => @combos.first, :photo_one_answer => "interested")
      combo_with_person_you_are_interested_in = Factory.create(:combo, :photo_two => @combos.first.photo_two)
      @game = Factory.create(:game, :player => @combos.first.photo_one.player)
      @game.combos(10).length.should == 2
      @game.combos(10).should_not include(combo_with_person_you_are_interested_in)
    end

    it "should show a couple combo if it is available" do
      couple_response = Factory.create(:response, :photo_one_answer => "good", :photo_two_answer => "good")
      couple_response.combo.photos.each { |p| p.update_attributes(:couple_combo_id => couple_response.combo_id) }
      couple_response.combo.update_attributes(:active => false)
      @game.combos(10).map(&:id).should include(couple_response.combo_id)
    end

    describe "filter photos from the same user" do
      before :each do
        @player_with_two_photos = @combos.first.photo_one.player
        @photo = Factory.create(:photo, :player => @player_with_two_photos)
        @combo = Factory.create(:combo, :photo_one => @photo)
      end

      it "should not duplicate any photos from the same user in a game" do
        game_combos = @game.combos(4)

        photo_players = game_combos.collect {|c|[c.photo_one.player, c.photo_two.player]}.flatten.uniq
        photo_players.length.should == 6
        game_combos.length.should == 3
      end
    end

    describe "trending yes/no matches by game answers" do
      it "should include 25% trending good matches if possible" do
        trending_yes_1 = Factory.create(:combo, :yes_count => 3, :no_count => 1)
        trending_yes_2 = Factory.create(:combo, :yes_count => 4, :no_count => 1)
        @game.combos(8).sort.should include(trending_yes_1, trending_yes_2)
      end

    end

  end

  describe "check_completed" do
    it "should do nothing if not a challenge game" do
      Factory.create(:game).check_completed
    end

    it "should notify the challenge_player if a challenge game" do
      challenge_player = Factory.create(:challenge).challenge_players.first
      game = challenge_player.create_game

      game.check_completed.should be_true
    end
  end
end
