class College < ActiveRecord::Base
  has_many :photos
  has_many :players
  has_many :photo_pairs
  has_many :combos

  def self.find_or_create_from_fb_data(fb_education_data)
    return nil if fb_education_data.blank?
    all_colleges = fb_education_data.select do |school_data|
      school_data["type"] == "College"
    end

    college_info = all_colleges.select { |c| College.find_by_id(c["school"]["id"]).try(:verified?) }.last
    college_info = all_colleges.last if college_info.nil?
    return nil if college_info.nil?
    college_data = college_info["school"]

    if (college = College.where(:fb_id => college_data["id"]).first)
      college
    else
      create!(:name => college_data["name"], :fb_id => college_data["id"])
    end
  end

  def self.find_or_create_from_fb_location_data(fb_location_data)
    return nil if fb_location_data.blank?

    location_id = fb_location_data["id"]
    return nil if location_id.nil?
    
    if (college = College.where(:fb_id => location_id).first)
      college
    else
      nil
    end
  end
end
