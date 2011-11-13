require 'spec_helper'

describe CouplesController do

  describe "new" do
    it "should show the top rated couples" do

    end

    it "should allow people to create a new couple" do

    end
  end

  describe "create" do
    it "should create a new player with 2 photos that are coupled with each other" do
      player = Factory.create(:player)
      set_session_for_player(player)

      post :create, :couple => {
        :photo_one => {:image => file_upload_fixture("cow.jpg", "image/jpg")},
        :photo_two => {:image => file_upload_fixture("bug.jpg", "image/jpg")},
        :email => "test@example.com"
      }

      photo_two = Photo.last

      photo_two.image_file_name.should =~ /bug/
      photo_two.couple_combo_id.should_not be_blank
      photo_two.current_state.should == 'confirmed'

      combo = photo_two.couple_combo
      combo.should_not be_active
      combo.response.photo_one_answer.should == "good"
      combo.response.photo_two_answer.should == "good"

      photo_one = combo.other_photo(photo_two)
      photo_one.image_file_name.should =~ /cow/
      photo_one.current_state.should == 'confirmed'

      photo_one.player.should == player
      photo_two.player.should == player

      player.reload.user.email.should == 'test@example.com'
    end

    it "should not break if you enter an email that already exists" do
      registered_player = Factory.create(:registered_player)

      post :create, :couple => {
        :photo_one => {:image => file_upload_fixture("cow.jpg", "image/jpg")},
        :photo_two => {:image => file_upload_fixture("bug.jpg", "image/jpg")},
        :email => registered_player.email
      }

      response.should be_success
    end

    it "should create a friend_couple if the params call for it" do
      player = Factory.create(:player)
      set_session_for_player(player)

      combo = Factory.create(:combo)

      post :create, :couple => {
        :photo_one => {:image => file_upload_fixture("cow.jpg", "image/jpg")},
        :photo_two => {:image => file_upload_fixture("bug.jpg", "image/jpg")},
        :email => "test@example.com"
      }, :cf => combo.id.to_obfuscated

      couple_friend = CoupleFriend.all.only
      couple_friend.combo_id.should == Combo.last.id
      couple_friend.other_combo_id.should == combo.id
    end

    it "should not fail and provide feedback if only one photo is added" do
      player = Factory.create(:player)
      set_session_for_player(player)

      post :create, :couple => {
        :photo_one => {:image => file_upload_fixture("cow.jpg", "image/jpg")},
        :email => "test@example.com"
      }

      Photo.coupled.count.should == 0
    end

    it "should not fail and provide feedback if no email is provided" do
      player = Factory.create(:player)
      set_session_for_player(player)

      post :create, :couple => {
        :photo_one => {:image => file_upload_fixture("cow.jpg", "image/jpg")},
        :photo_two => {:image => file_upload_fixture("bug.jpg", "image/jpg")},
        :email => ""
      }

      Photo.coupled.count.should == 0
    end
  end

end
