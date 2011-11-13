require 'spec_helper'

describe MatchMeAnswer do
  describe "friend_suggestions" do
    before :each do
      @target_photo = Factory(:female_photo, :player => Factory(:registered_player))
      @friend = Factory(:player)
      @another_friend = Factory(:player)
      male_photos = []
      6.times do |i|
        male_photos << Factory(:male_photo)
      end
      @suggested_matches = male_photos.select { |m| m.id.even? }
      @suggested_matches.each do |suggestion|
        MatchMeAnswer.create(:player => @friend, :answer => "y", :target_photo => @target_photo, :other_photo => suggestion)
      end
      MatchMeAnswer.create(:player => @another_friend, :answer => "y", :target_photo => @target_photo, :other_photo => @suggested_matches[1])
    end

    it "should return any friend suggestions" do
      suggestions = MatchMeAnswer.friend_suggestions(@target_photo)
      suggestions.map { |suggestion| suggestion[:photo] }.should =~ @suggested_matches
    end

    it "should prioritize any friend suggestions with the most matches from different friends" do
      suggestions = MatchMeAnswer.friend_suggestions(@target_photo)
      suggestions.first[:photo].should == @suggested_matches[1]
    end

    it "should prioritize any suggestions you haven't answered yet" do
      @suggested_matches[0..1].each do |suggestion|
        MatchMeAnswer.create(:player => @target_photo.player, :answer => "y", :target_photo => @target_photo, :other_photo => suggestion)
      end

      suggestions = MatchMeAnswer.friend_suggestions(@target_photo)
      suggestions.first[:photo].should == @suggested_matches.last
    end
  end
end
