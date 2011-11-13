require 'spec_helper'

describe MatchMeGame do
  before :each do
    @target_photo = Factory(:registered_photo, :bucket => nil)
    @friend = Factory(:player)
    6.times do |i|
      male = Factory(:male_photo)
      female = Factory(:female_photo)
      Factory(:combo, :photo_one => male, :photo_two => female)
    end
  end

  describe "combos" do

    it "should generate combos" do
      match_me_game = MatchMeGame.create(@target_photo, @friend)
      match_me_game.game.player.should == @friend

      combos = match_me_game.combos(5)

      combos.length.should == 5

      all_photo_ids = combos.collect{|combo|[combo.photo_one.id, combo.photo_two.id]}.flatten
      all_photo_ids.select{|id|id == @target_photo.id}.length.should == 5

    end

    it "should not match with paused photos" do
      match_me_game = MatchMeGame.create(@target_photo, @friend)
      match_me_game.game.player.should == @friend

      Photo.where("gender = 'f'").limit(4).all.each { |p| p.pause! }

      combos = match_me_game.combos(5)

      combos.length.should == 2

      all_photos = combos.collect{|combo|[combo.photo_one, combo.photo_two]}.flatten
      all_photos.select{|p|p == @target_photo}.length.should == 2
      all_photos.detect{ |p| p.paused? }.should be_nil
    end


    it "should prioritize and photos where the other person said it was a good match" do
      good_match_photo = Factory(:female_photo)
      MatchMeAnswer.create(:target_photo => good_match_photo, :other_photo => @target_photo, :answer => 'y', :player => good_match_photo.player)
      match_me_game = MatchMeGame.create(@target_photo, @friend)
      combos = match_me_game.combos(1)
      combos.length.should == 1
      combos.select{|c|c.kind_of? MatchMeCombo}.collect { |c| [c.photo_one.id, c.photo_two.id] }.flatten.sort.should == [good_match_photo.id, @target_photo.id].sort
    end


    describe "existing answers" do
      before :each do
        @match_me_game = MatchMeGame.create(@target_photo, @friend)

        combos = @match_me_game.combos(4)
        @match_me_combos = combos.select{|c|c.kind_of? MatchMeCombo}
        @match_me_combos.length.should == 4

        @match_me_combos.each do |c|
          MatchMeAnswer.create(:player => @friend, :answer => "y", :target_photo => c.photo, :other_photo => c.other_photo)
        end

      end

      it "should not match with already answered photos" do
        remaining_match_me_combos = @match_me_game.combos(8).select{|c|c.kind_of? MatchMeCombo}
        remaining_match_me_combos.length.should == 2

        (@match_me_combos - remaining_match_me_combos).length.should == 4

        remaining_match_me_combos.each do |c|
          MatchMeAnswer.create(:player => @friend, :answer => "y", :target_photo => c.photo, :other_photo => c.other_photo)
        end

        more_remaining_match_me_combos = @match_me_game.combos(8).select{|c|c.kind_of? MatchMeCombo}
        more_remaining_match_me_combos.length.should == 0
      end


      it "should not reshow combos when other person has said yes" do
        combo = @match_me_combos.first
        MatchMeAnswer.create(:player => Factory(:player), :answer => "y", :target_photo => combo.other_photo, :other_photo => combo.photo)

        remaining_match_me_combos = @match_me_game.combos(8).select{|c|c.kind_of? MatchMeCombo}
        remaining_match_me_combos.length.should == 2
      end
    end

    describe "other answered yes" do
      it "should not show duplicate photos" do
        other_photo = Factory(:female_photo)
        PhotoPair.create(:photo => @target_photo, :other_photo => other_photo)
        MatchMeAnswer.create(:player_id => other_photo.player_id, :target_photo => other_photo, :other_photo => @target_photo, :answer => "y")

        @match_me_game = MatchMeGame.create(@target_photo, @target_photo.player)

        other_photos = @match_me_game.combos(10).map(&:other_photo)
        other_photos.should include(other_photo)
        other_photos.uniq.length.should == other_photos.length

      end
    end
  end

end
