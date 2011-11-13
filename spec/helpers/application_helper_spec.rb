require 'spec_helper'

describe ApplicationHelper do
  it "should emit both urls for processed images" do
    processing_photo = Factory.create(:photo, :image => File.new("#{fixture_path}/cow.jpg"))

    tag_html = helper.processed_image_group(processing_photo)
    parsed = Nokogiri::HTML.parse(tag_html)
    parsed.css("img").length.should == 2
    parsed.css("img.processed_group_loading").length.should == 1
    parsed.css("img.processed_group_loaded").length.should == 1
    parsed.css("img.processed_group_loading")[0]['style'].should be_nil
    parsed.css("img.processed_group_loaded")[0]['style'].should == "display: none;"
    parsed.css("img.processed_group_loading")[0]['src'].should =~ /loading/
    parsed.css("img.processed_group_loaded")[0]['src'].should =~ /cow/
    parsed.css("img.processed_group_loaded")[0]['data-src'].should =~ /cow/

    processing_photo.update_attribute(:image_processing, false)

    tag_html = helper.processed_image_group(processing_photo)
    parsed = Nokogiri::HTML.parse(tag_html)
    parsed.css("img").length.should == 1
    parsed.css("img.processed_group_loading").length.should == 0
    parsed.css("img.processed_group_loaded").length.should == 0
    parsed.css("img")[0]['src'].should =~ /cow/
  end
end
