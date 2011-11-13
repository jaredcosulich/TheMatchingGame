require 'spec_helper'

describe RegistersController do

  describe "show" do
    it "should show to new players" do
      get :show
      response.should render_template(:show)
    end

    it "should show to existing players" do
      set_session_for_player Factory.create(:player)
      get :show
      response.should render_template(:show)
    end

    it "should show to registered users" do
      set_session_for_player Factory.create(:registered_player)
      get :show
      response.should render_template(:show)
    end

    it "should redirect users with photos to account" do
      player = Factory.create(:photo).player
      set_session_for_player player

      get :show
      response.should redirect_to new_photo_path
    end
  end

  describe "new" do
    describe "new player" do
      it "should render" do
        get :new
        response.should be_success
        response.should render_template(:new)
      end
    end

    describe "existing player" do
      it "should render" do
        set_session_for_player Factory.create(:player)

        get :new

        response.should be_success
        response.should render_template(:new)
      end

      describe "with user" do
        it "should skip step 1" do
          set_session_for_player Factory.create(:registered_player)

          get :new

          response.should be_success
          response.should render_template(:new)
        end

        it "should blank out fb_emails" do
          set_session_for_player player = Factory.create(:player)
          User.find_or_create_fb(player.id, 123456789)
          get :new

          response.should be_success
          response.should render_template(:new)

          assigns[:current_player].email.should be_blank
        end

        it "should not blank out fb_emails" do
          set_session_for_player Factory.create(:registered_player)
          get :new

          response.should be_success
          response.should render_template(:new)

          assigns[:current_player].email.should_not be_blank
        end
      end

      describe "with profile" do
        it "should redirect to new photo" do
          player = Factory(:player)
          Factory(:profile, :player => player)
          set_session_for_player player

          get :new

          response.should redirect_to(new_photo_path)
        end
      end

    end
  end


  describe "create" do
    it "should create a user, profile, and photo, and redirect to photo/show for confirmation/cropping" do
      post :create, {
        "player" => {"connectable"=>"t", "gender"=>"m",
                     "user_attributes"=>{"password_confirmation"=>"123456", "password"=>"123456", "email"=>"adam@abrons.com", "terms_of_service"=> "1"},
                     "profile_attributes"=>{"location_lat"=>"37.775", "birthdate(1i)"=>"1986", "birthdate(2i)"=>"4", "birthdate(3i)"=>"5", "last_name"=>"Cosulich", "location_lng"=>"-122.419", "first_name"=>"Jared", "location_name"=>"San Francisco, CA, USA"},
                     "photo"=>{"image"=>file_upload_fixture("cow.jpg", "image/jpg")},
          }
        }

      player = Player.last
      player.should be_connectable
      player.gender.should == 'm'
      player.user.email.should == 'adam@abrons.com'
      player.profile.first_name.should == "Jared"
      player.profile.last_name.should == "Cosulich"
      player.profile.birthdate.should == Date.parse("04/05/1986")
      player.profile.location_name.should == "San Francisco, CA, USA"
      player.profile.location_lat.should == 37.775
      player.profile.location_lng.should == -122.419
      player.photos.length.should == 1
      player.photos.first.image_file_name.should == 'cow.jpg'
      response.should redirect_to(photo_path(player.photos.first))
    end

    it "should update user_attributes if already has user" do
      user = Factory.create(:user, :email => "e@example.com")
      User.count.should == 1
      set_session_for_player user.player
      post :create, {
        "player" => {"connectable"=>"t", "gender"=>"m",
                     "user_attributes"=>{"id" => user.to_param, "email"=>"adam@abrons.com", "password_confirmation"=>"123456", "password"=>"123456", "terms_of_service"=> "1"},
                     "profile_attributes"=>{"location_lat"=>"37.775", "birthdate(1i)"=>"1986", "birthdate(2i)"=>"4", "birthdate(3i)"=>"5", "last_name"=>"Cosulich", "location_lng"=>"-122.419", "first_name"=>"Jared", "location_name"=>"San Francisco, CA, USA"},
                     "photo"=>{"image"=>file_upload_fixture("cow.jpg", "image/jpg")}
          }
        }
      user.reload.email.should == "adam@abrons.com"
      response.should redirect_to(photo_path(user.player.photos.last))
      User.count.should == 1
    end


    it "should create a photo from facebook if then connected to facebook" do
      Photo.should_receive(:download_image).with("/facebook/url/").and_return(File.new("#{fixture_path}/cow.jpg"))
      post :create, {
        "player" => {"connectable"=>"t", "gender"=>"m",
                     "user_attributes"=>{"email"=>"adam@abrons.com", "password_confirmation"=>"123456", "password"=>"123456", "terms_of_service"=> "1"},
                     "profile_attributes"=>{"location_lat"=>"37.775", "birthdate(1i)"=>"1986", "birthdate(2i)"=>"4", "birthdate(3i)"=>"5", "last_name"=>"Cosulich", "location_lng"=>"-122.419", "first_name"=>"Jared", "location_name"=>"San Francisco, CA, USA"},
          },
        "facebook_photo"=>"/facebook/url/"}

      player = Player.last
      player.photos.length.should == 1
      player.photos.first.image_file_name.should == 'cow.jpg'
      response.should redirect_to(photo_path(player.photos.first))
    end

    it "should prompt to retry if facebook times out" do
      Photo.should_receive(:download_image).with("/facebook/url/").and_raise(Timeout::Error.new)
      post :create, {
        "player" => {"connectable"=>"t", "gender"=>"m",
                     "user_attributes"=>{"email"=>"adam@abrons.com", "password_confirmation"=>"123456", "password"=>"123456", "terms_of_service"=> "1"},
                     "profile_attributes"=>{"location_lat"=>"37.775", "birthdate(1i)"=>"1986", "birthdate(2i)"=>"4", "birthdate(3i)"=>"5", "last_name"=>"Cosulich", "location_lng"=>"-122.419", "first_name"=>"Jared", "location_name"=>"San Francisco, CA, USA"},
          },
        "facebook_photo"=>"/facebook/url/"}

      player = Player.last
      player.photos.should be_empty

      response.should redirect_to(new_photo_path)
    end

    it "should redirect to new photo path with a flash if no photo info received" do
      post :create, {
        "player" => {"connectable"=>"t", "gender"=>"m",
                     "user_attributes"=>{"email"=>"adam@abrons.com", "password_confirmation"=>"123456", "password"=>"123456", "terms_of_service"=> "1"},
                     "profile_attributes"=>{"location_lat"=>"37.775", "birthdate(1i)"=>"1986", "birthdate(2i)"=>"4", "birthdate(3i)"=>"5", "last_name"=>"Cosulich", "location_lng"=>"-122.419", "first_name"=>"Jared", "location_name"=>"San Francisco, CA, USA"},
          }
        }

      player = Player.last
      player.photos.length.should == 0
      player.user.email.should == 'adam@abrons.com'
      player.profile.first_name.should == "Jared"
      flash[:notice].should_not be_blank
      response.should redirect_to(new_photo_path)
    end

    it "should render :new with validation errors if missing info" do
      post :create, {
        "player" => {"connectable"=>"t", "gender"=>"m",
                     "user_attributes"=>{"email" => "a@example.com"},
                     "profile_attributes"=>{"first_name"=>"Jared"},
          }
        }
      response.should render_template(:new)
      assigns[:current_player].should be_new_record
      assigns[:current_player].user.should be_new_record
      assigns[:current_player].user.email.should == "a@example.com"
      assigns[:current_player].profile.should be_new_record
      assigns[:current_player].profile.first_name.should == "Jared"

    end

  end

end
