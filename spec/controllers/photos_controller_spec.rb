require 'spec_helper'

describe PhotosController do

  describe "new" do
    render_views

    it "should redirect to registers/new if no profile created" do
      set_session_for_player Factory.create(:registered_player)
      get :new

      response.should redirect_to new_register_path(:ref => "new_photo")
    end

    it "should prompt for a photo if profile created" do
      set_session_for_player player = Factory.create(:registered_player)
      Factory.create(:profile, :player => player)
      get :new

      assert_select("form[enctype=?]", "multipart/form-data")
      assert_select("input[name=?][type=?]", "photo[image]", "file")
    end

    it "should prompt for a photo if profile created" do
      set_session_for_player player = Factory.create(:registered_player)
      Factory.create(:facebook_profile, :player => player)
      get :new

      assert_select("form[enctype=?]", "multipart/form-data")
      assert_select("input[name=?][type=?]", "photo[image]", "file")
    end

    it "should show a message if you already have the max number of photos" do
      player = Factory.create(:registered_player)
      Factory.create(:profile, :player => player)
      set_session_for_player player
      Features.max_photos_per_user.times { photo = Factory.create(:photo, :player => player); photo.confirm!; photo.approve! }
      player.reload.photos.length.should == Features.max_photos_per_user
      get :new
      response.body.should include("maximum")

      player.photos.last.pause!
      
      get :new
      response.body.should_not include("maximum")
    end

  end

  describe "show" do
    before :each do
      @player = Factory.create(:registered_player)
      set_session_for_player(@player)
    end

    [:unconfirmed, :confirmed, :approved, :rejected, :paused, :paused_unapproved].each do |state|
      it "should work for #{state} state" do
        get :show, :id => Factory.create(:photo, :player => @player, :current_state => state.to_s).to_param
        response.should be_success
      end
    end

    it "should show error if wrong player" do
      get :show, :id => Factory.create(:photo).to_param
      response.code.should == "404"
    end

    it "should redirect if integer id" do
      photo = Factory.create(:photo, :player => @player)
      get :show, :id => photo.id.to_s
      response.should redirect_to(photo_path(photo))
    end
  end

  describe "index" do
    before :each do
      @player = Factory.create(:registered_player)
      set_session_for_player(@player)
    end

    describe 'subtabs' do
      before :each do
        ActiveRecord::Observer.with_observers(:combo_observer) do
          @photo = Factory.create(:photo, :player => @player, :current_state => 'approved')

          @awaiting_response_great = Factory.create(:combo, :photo_one => @photo, :yes_count => 7, :no_count => 1)
          @awaiting_response_good = Factory.create(:combo, :photo_one => @photo, :yes_count => 5, :no_count => 2)

          @awaiting_response_other_interested = Factory.create(:response, :photo_two_answer => 'interested', :combo => Factory.create(:combo, :photo_one => @photo)).combo
          @responded_bad =  Factory.create(:response, :photo_one_answer => 'bad', :combo => Factory.create(:combo, :photo_one => @photo)).combo
          @responded_good =  Factory.create(:response, :photo_one_answer => 'good', :combo => Factory.create(:combo, :photo_one => @photo)).combo
          @responded_good_them_not_connectable =  Factory.create(:response, :photo_one_answer => 'good', :combo => Factory.create(:combo, :photo_one => @photo, :photo_two => Factory.create(:not_connectable_photo))).combo
          @responded_interested =  Factory.create(:response, :photo_one_answer => 'interested', :combo => Factory.create(:combo, :photo_one => @photo)).combo
          @responded_uninterested =  Factory.create(:response, :photo_one_answer => 'uninterested', :combo => Factory.create(:combo, :photo_one => @photo)).combo


          @awaiting_response_great.save!
          @awaiting_response_good.save!

          work_all_jobs
          
          @awaiting_response_great.reload.response.should_not be_nil
          @awaiting_response_good.reload.response.should_not be_nil
        end
      end

      describe "matches tabs" do
        before :each do
          @player.update_attribute(:connectable, false)
        end

        it "should show only one's you haven't finished answering for 'awaiting your response tab' - default tab" do
          Response.reveal_some
          Response.where("revealed_at > now()").each { |r| r.update_attribute(:revealed_at, 1.hour.ago)}

          get :index
          response.should be_success
          assigns[:matches].map(&:id).should =~ [@awaiting_response_good, @awaiting_response_great, @awaiting_response_other_interested].map(&:id)
        end

        it "should show only ones that you are interested in connecting with, but they have not responded" do
          get :index, :t => "good"
          response.should be_success
          assigns[:matches].should == [@responded_uninterested, @responded_interested, @responded_good_them_not_connectable, @responded_good]
        end

        it "should work when the user has 2 photos" do
          Factory.create(:photo, :player => @player, :current_state => 'approved')
          get :index, :t => "good"
          response.should be_success
          assigns[:matches].should == [@responded_uninterested, @responded_interested, @responded_good_them_not_connectable, @responded_good]
        end

        it "should show only ones that you are not interested in connecting with" do
          get :index, :t => "bad"
          response.should be_success
          assigns[:matches].should == [@responded_bad]
        end


      end
    end
  end

  describe "create" do
    before :each do
      set_session_for_player @player = Factory.create(:registered_player)
    end

    it "should create an unconfirmed photo with gender" do
      post :create, :photo => {:image => file_upload_fixture("cow.jpg", "image/jpg"), :player => {:gender => "f"}}

      photo = Photo.find(:last)
      photo.player.should == assigns[:current_player]
      photo.should_not be_approved
      photo.should_not be_rejected
      photo.gender.should == "f"
      photo.player.gender.should == "f"
      Photo.unconfirmed.should include(photo)
      photo.image.url.should_not be_blank
    end

    it "should create an unconfirmed photo with gender 'u' if player has no gender" do
      @player.update_attribute(:gender, "u")
      post :create, :photo => {:image => file_upload_fixture("cow.jpg", "image/jpg")}

      photo = Photo.find(:last)
      photo.player.should == assigns[:current_player]
      photo.should_not be_approved
      photo.should_not be_rejected
      photo.gender.should == "u"
      Photo.unconfirmed.should include(photo)
      photo.image.url.should_not be_blank
    end

    it "should copy gender from player if available" do
      set_session_for_player (Factory.create(:registered_player, :gender => "f"))
      post :create, :photo => {:image => file_upload_fixture("cow.jpg", "image/jpg")}

      photo = Photo.find(:last)
      photo.player.should == assigns[:current_player]
      photo.gender.should == "f"
    end

    it "should require if not set on player" do
      set_session_for_player (Factory.create(:registered_player, :gender => ""))
      post :create, :photo => {:image => file_upload_fixture("cow.jpg", "image/jpg")}

      response.should render_template(:new)
      Photo.count.should == 0
      
    end

    it "should require photo" do
      post :create

      response.should render_template(:new)
      Photo.count.should == 0
      assigns[:photo].errors[:image_file_name].should_not be_blank
    end

    it "should redirect to the photo path (for confirmation)" do
      post :create, :photo => {:image => file_upload_fixture("cow.jpg", "image/jpg"), :player => {:gender => "m"}}
      response.should redirect_to(photo_path(Photo.last))
    end


  end

  describe "confirm" do
    before :each do
      @photo = Factory.create(:photo, :player => Factory.create(:registered_player))
    end
    it "should confirm and redirect to the photo page" do
      set_session_for_player @photo.player

      post :confirm, :id => @photo.to_param

      response.should redirect_to photo_path(@photo)
      @photo.reload.current_state.should == "confirmed"
    end

    it "should not break if already confirmed" do
      set_session_for_player @photo.player
      @photo.confirm!

      post :confirm, :id => @photo.to_param

      response.should redirect_to photo_path(@photo)
      @photo.reload.current_state.should == "confirmed"
    end

    it "should not confirm and produce an error if not the right player" do
      set_session_for_player Factory.create(:registered_player)

      post :confirm, :id => @photo.to_param

      response.code.should == "404"
      @photo.reload.current_state.should == "unconfirmed"
    end
  end

  describe "edit" do
    it "should allow user to change the photo if unconfirmed" do
      photo = Factory.create(:registered_photo)
      login_as photo.player.user

      get :edit, :id => photo.to_param

      response.should render_template("edit")
    end


    it "should not be allowed if confirmed" do
      photo = Factory.create(:confirmed_photo, :player => Factory.create(:registered_player))
      login_as photo.player.user

      get :edit, :id => photo.to_param

      response.should redirect_to(photo_path(photo))
      flash[:notice].should == "This photo has been confirmed and cannot be changed.<br/><br/>You can pause or remove this photo and add another one."
    end
  end

  describe "update" do
    it "should update the photo if unconfirmed" do
      photo = Factory.create(:registered_photo)
      login_as photo.player.user

      photo.image_file_name.should == "image_file_name"
      Delayed::Job.count.should == 2

      put :update, :id => photo.to_param, :photo => {:image => file_upload_fixture("cow.jpg", "image/jpg")}

      photo.reload.image_file_name.should == "cow.jpg"

      Delayed::Job.count.should == 3
    end

    it "should reject the update if already confirmed" do
      photo = Factory.create(:confirmed_photo, :player => Factory.create(:registered_player))
      login_as photo.player.user

      photo.image_file_name.should == "image_file_name"
      Delayed::Job.count.should == 2

      put :update, :id => photo.to_param, :photo => {:image => file_upload_fixture("cow.jpg", "image/jpg")}

      response.should redirect_to(photo_path(photo))
      flash[:notice].should == "This photo has been confirmed and cannot be changed.<br/><br/>You can pause or remove this photo and add another one."
      photo.reload.image_file_name.should == "image_file_name"

      Delayed::Job.count.should == 2
    end
  end

  describe "facebook" do
    it "should handle not selecting a photo" do
      post :facebook
      response.should redirect_to(new_photo_path)
      flash[:notice].should =~ /Please select one of your Facebook photos/
    end

    it "should handle not selecting a photo" do
      Photo.should_receive(:download_image).with("/facebook/url/").and_return(File.new("#{fixture_path}/cow.jpg"))
      post :facebook, :facebook_photo => "/facebook/url/"
      response.should redirect_to(photo_path(Photo.last))
    end

  end

  describe "update_player" do
    before :each do
      @photo = Factory(:registered_photo)
      @player = @photo.player
      set_session_for_player(@player)
     end

    it "should save the interests" do
      interests = [
        "Running",
        "Poodles",
        "Celtics",
        "Chicken",
        "Lasagna",
        "Dancing"
      ]

      post :update_player, :id => @photo.to_param, :interests => interests.collect { |interest| {:title => interest} }

      response.should redirect_to(photo_path(@photo))
      @player.reload
      @player.interests.map(&:title).should =~ interests
    end

    it "should update email" do
      post :update_player, :id => @photo.to_param, :player => {:user_attributes => {:email => "updated@test.com" } }

      response.should redirect_to(photo_path(@photo))
      flash[:notice].should =~ /success/i
      @player.reload.user.email.should == "updated@test.com"
    end

    it "should show errors" do
      Factory(:user, :email => "user@example.com")

      post :update_player, :id => @photo.to_param, :player => {:user_attributes => {:email => "user@example.com" } }

      response.should redirect_to(photo_path(@photo))

      flash[:notice].to_s.should =~ /taken/
      @player.reload.user.email.should_not == "user@example.com"
    end
  end

end
