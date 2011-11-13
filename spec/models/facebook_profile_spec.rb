require 'spec_helper'

describe FacebookProfile do
  before :each do
    @facebook_profile = Factory.create(:facebook_profile)
  end

  describe "profile attributes" do
    it "should correctly profile attributes" do
      @facebook_profile.first_name.should == "Adam"
      @facebook_profile.full_name.should == "Adam Abrons"
      @facebook_profile.name_age_and_place.should == "Adam A. (39 yrs)"
      @facebook_profile.age.should == 39
      @facebook_profile.location_name.should be_blank
    end
  end

  describe "merge_fb_info" do
    before :each do
      @facebook_profile.merge_fb_info({"last_name" => "LAST", "current_location" =>  {
        "city"=> "Palo Alto",
        "country"=> "United States",
        "id"=> 104022926303756,
        "name"=> "Palo Alto, California",
        "state"=> "California",
        "zip"=> ""
      }})
      @facebook_profile.save!
      @facebook_profile.reload
    end

    it "should merge location" do
      @facebook_profile.location_name.should == "Palo Alto, California"
    end

    it "should update last name" do
      @facebook_profile.last_name.should == "LAST"
    end

    it "should preserve first name" do
      @facebook_profile.first_name.should == "Adam"

    end
  end


  describe "#create_user_from_fb_data" do
    describe "user creation" do
      before :each do
        @user = FacebookProfile.create_user_from_fb_data(user_data_obj)
      end

      it "should create a user with the correct email and fb_id" do
        @user.email.should == "jared.cosulich@gmail.com"
        @user.fb_id.should == 580888580
      end


      describe "side effects" do
        it "should have a valid college" do
          college = @user.reload.player.college
          college.should_not be_nil
          college.fb_id.should == "103119943060893"
        end

        it "should have a valid player" do
          @user.player.should_not be_nil
          @user.player.should_not be_new_record
          @user.player.gender.should == "m"
        end

        it "should create a facebook_profile" do
          profile = @user.player.preferred_profile
          profile.class.should == FacebookProfile
          profile.fb_info.should_not be_nil
        end

      end


    end
  end

  def user_data_obj
    {"name"=>"Jared Cosulich",
     "location"=>{"name"=>"San Francisco, California", "id"=>"114952118516947"},
     "timezone"=>-7,
     "gender"=>"male",
     "id"=>"580888580",
     "birthday"=>"02/28/1980",
     "last_name"=>"Cosulich",
     "updated_time"=>"2011-08-23T17:55:17+0000",
     "verified"=>true,
     "locale"=>"en_US",
     "hometown"=>{"name"=>"Concord, Massachusetts", "id"=>"107710392585440"},
     "link"=>"http://www.facebook.com/profile.php?id=580888580",
     "email"=>"jared.cosulich@gmail.com",
     "education"=>
      [{"school"=>{"name"=>"Claremont McKenna College", "id"=>"103119943060893"},
        "type"=>"College",
        "year"=>{"name"=>"2002", "id"=>"194878617211512"}}],
     "work"=>
      [{"from"=>{"name"=>"Adam Abrons", "id"=>"15700"},
        "employer"=>{"name"=>"Irrational Design", "id"=>"213927585305536"},
        "with"=>[{"name"=>"Adam Abrons", "id"=>"15700"}]}],
     "first_name"=>"Jared"}
  end

end


