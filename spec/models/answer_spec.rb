require 'spec_helper'

describe Answer do

  before(:each) do
    @answer = Factory.create(:answer)
  end

  describe "include?" do
    it "should return true for the photos the answer contains" do
      @answer.should be_include(@answer.combo.photo_one)
      @answer.should be_include(@answer.combo.photo_two)
    end

    it "should return false for any photo the answer does not contain" do
      @answer.should_not be_include(Factory.create(:photo))
    end
  end

  describe "results" do
    it "should calculate percentages" do
      photo_1 = Factory.create(:photo, :gender => "f")
      photo_2 = Factory.create(:photo, :gender => "f")
      photo_3 = Factory.create(:photo)
      photo_4 = Factory.create(:photo)

      combo_1_3 = Factory.create(:combo, :photo_one => photo_1, :photo_two => photo_3)
      combo_1_4 = Factory.create(:combo, :photo_one => photo_1, :photo_two => photo_4)
      combo_2_3 = Factory.create(:combo, :photo_one => photo_2, :photo_two => photo_3)
      combo_2_4 = Factory.create(:combo, :photo_one => photo_2, :photo_two => photo_4)

      Factory.create(:answer, :combo => combo_1_3, :answer => "y")
      Factory.create(:answer, :combo => combo_1_3, :answer => "n")
      Factory.create(:answer, :combo => combo_1_4, :answer => "y")
      Factory.create(:answer, :combo => combo_1_4, :answer => "y")
      Factory.create(:answer, :combo => combo_2_3, :answer => "n")

      combo_1_3.yes_count.should == 1
      combo_1_3.no_count.should == 1
      combo_1_4.yes_count.should == 2
      combo_1_4.no_count.should == 0
      combo_2_3.yes_count.should == 0
      combo_2_3.no_count.should == 1
      combo_2_4.yes_count.should == 0
      combo_2_4.no_count.should == 0
    end
  end

  describe "set_viewed_at" do
    it "should set the viewed_at field for a bunch of answers" do
      other_answer = Factory.create(:answer)
      other_answer.combo.create_response(:photo_one_answer => 'bad')
      @answer.viewed_at.should be_nil
      other_answer.viewed_at.should be_nil
      Answer.set_viewed_at([other_answer, @answer])
      other_answer.reload
      @answer.reload
      other_answer.viewed_at.should_not be_nil
      @answer.viewed_at.should == other_answer.viewed_at
      (other_answer.viewed_at <= other_answer.combo.reload.state_changed_at).should be_true
    end

  end

  describe "kind" do
    it "should send kind on create" do
      player = Factory.create(:player)
      yes_combo = Factory.create(:response, :photo_one_answer => "good", :photo_two_answer => "good").combo
      first_game = Factory.create(:game, :player => player)
      first_answer = Factory.create(:answer, :game => first_game, "answer" => "y", :combo => yes_combo)
      first_answer_predicting = Factory.create(:answer, :game => first_game, "answer" => "n")


      second_game = Factory.create(:game, :player => player)
      second_answer = Factory.create(:answer, :game => second_game, "answer" => "n", :combo => yes_combo)
      second_answer_predicting = Factory.create(:answer, :game => second_game, "answer" => "n")


      first_answer.kind.should == "existed"
      first_answer_predicting.kind.should == "predicted"
      second_answer.kind.should == "existed"
      second_answer_predicting.kind.should == "predicted"

    end
  end

  describe "scopes" do
    it "should query unread" do
      answer = Factory(:answer)
      
      Answer.unread.should be_empty

      answer.combo.create_response(:photo_one_answer => "good")

      Answer.unread.should == [answer]
    end

    it "should find predicted_with_response_since" do
      answer = Factory(:answer)
      another_answer = Factory(:answer)

      Answer.unread.predicted_with_response_since(1.days.ago).should be_empty

      answer.combo.create_response(:photo_one_answer => "good")
      another_answer.combo.create_response(:photo_one_answer => "good")

      Answer.unread.predicted_with_response_since(1.days.ago).should == [answer, another_answer]
      answer.player.answer_scope.unread.predicted_with_response_since(1.days.ago).should == [answer]
      Factory(:player).answer_scope.unread.predicted_with_response_since(1.days.ago).should be_empty

#      answer.player.answers.unread.predicted_with_response_since(1.days.ago).should == [answer]
      Answer.unread.predicted_with_response_since(2.days.from_now).should be_empty
    end

  end
end
