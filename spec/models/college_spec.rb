
require 'spec_helper'

describe College do

  describe "#find_or_create_from_fb_data" do
    before :each do
      @fb_college_id = "103119943060893"
      @fb_college_name = "Claremont McKenna College"
    end

    it "should create a new unverified college if the college does not yet exist" do
      College.find_by_id(@fb_college_id).should be_nil
      college = College.find_or_create_from_fb_data(fb_data)
      college.should_not be_nil
      college.name.should == @fb_college_name
      college.fb_id.should == @fb_college_id
      college.verified.should be_false
    end

    it "should not create a new college if it already exists" do
      existing_college = College.create(:fb_id => @fb_college_id, :name => @fb_college_name)
      college = College.find_or_create_from_fb_data(fb_data)
      College.where(:fb_id => @fb_college_id).count.should == 1
      college.should == existing_college
    end
  end

  def fb_data
    [
      {
        "school"=>{
          "name"=>"Claremont McKenna College",
          "id"=>"103119943060893"
        },
        "type"=>"College",
        "year"=>{"name"=>"2002", "id"=>"194878617211512"}
      },
      {
        "school"=>{
          "name"=>"Highschool",
          "id"=>"89935487235"
        },
        "type"=>"Highschool",
        "year"=>{"name"=>"1998", "id"=>"987342928374"}
      }
    ]
  end

end
