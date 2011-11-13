require 'spec_helper'

describe Combinator do
  describe "new_combos" do
    describe "normal_circumstances" do
      before(:each) do
        @females = []
        @males = []
        2.times do
          @females << Factory.create(:female_photo)
          @males << Factory.create(:male_photo)
        end
      end

      it "should create up to N combos of the opposite sex" do
        new_photo = Factory.create(:male_photo)

        new_photo.reload.active_combos.size.should == 0;

        combos = Combinator.new_combos(new_photo, 10)

        combos.length.should == 2
        combos.collect{|c|[c.photo_one, c.photo_two]}.flatten.should =~ @females + [new_photo, new_photo]
      end

      it "should create N combos if possible" do
        5.times { @females << Factory.create(:female_photo) }
        new_photo = Factory.create(:male_photo)

        combos = Combinator.new_combos(new_photo, 3)
        combos.length.should == 3
        (combos.collect{|c|c.other_photo(new_photo)} - @females).should be_empty
      end

      it "should only create combos with approved photos" do
        photo_one = Factory.create(:confirmed_photo, :gender => "m")
        photo_two = Factory.create(:confirmed_photo, :gender => "f")
        couple_combo = Combo.find_or_create_by_photo_ids(photo_one.id, photo_two.id)
        photo_one.update_attribute(:couple_combo, couple_combo)
        photo_two.update_attribute(:couple_combo, couple_combo)
        photo_one.approve!
        photo_two.approve!

        new_photo = Factory.create(:female_photo)

        combos = Combinator.new_combos(new_photo, 10)
        combos.length.should == 2
        (combos.collect{|c|c.other_photo(new_photo)} - @males).should be_empty
      end

      it "should never create combos with photos that are part of a couple combo" do
        couple_combo = Factory(:combo)
        couple_combo.photo_one.update_attribute(:couple_combo, couple_combo)
        couple_combo.photo_two.update_attribute(:couple_combo, couple_combo)

        new_photo = Factory.create(:female_photo)

        combos = Combinator.new_combos(new_photo, 5)
        combos.length.should == 2
        (combos.collect{|c|c.other_photo(new_photo)} - @males).should be_empty
      end
    end

    describe "college interactions" do
      before :each do
        @college = Factory(:college)
        @unverified_college = Factory(:college, :verified => false)
        @guy = Factory.create(:male_photo)
        @college_guy = Factory.create(:male_photo, :college => @college)
        @college_girl = Factory.create(:female_photo, :college => @college)
        @different_college_girl = Factory.create(:female_photo, :college => Factory(:college))
        @unverified_college_guy = Factory.create(:male_photo, :college => @unverified_college)
        @unverified_college_girl = Factory.create(:female_photo, :college => @unverified_college)
        @girl = Factory.create(:female_photo)
      end

      it "should only match up photos that belong to a college with other photos from the same college" do
        combos = Combinator.new_combos(@college_guy, 10)
        combo = combos.only
        combo.other_photo(@college_guy).should == @college_girl
        combo.college.should == @college
      end

      it "should not match up college photos with other photos" do
        combos = Combinator.new_combos(@guy, 10)
        combo = combos.only
        combo.other_photo(@guy).should == @girl
        combo.college.should be_nil
      end

      it "should not match up photos associated with an unverified college at all" do
        Combinator.new_combos(@unverified_college_guy, 10).should be_empty
      end
    end

    describe "same_sex" do
      before :each do
        @guy = Factory.create(:male_photo)
        @girl = Factory.create(:female_photo)
        @same_sex_girl = Factory.create(:female_photo, :same_sex => true)
        @same_sex_guy = Factory.create(:male_photo, :same_sex => true)
        @same_sex_guy2 = Factory.create(:male_photo, :same_sex => true)
      end

      it "should only match up photos for same_sex with other photos of same_sex" do
        same_sex_guy_combos = Combinator.new_combos(@same_sex_guy, 10)
        same_sex_guy_combos.only.other_photo(@same_sex_guy).should == @same_sex_guy2
      end

      it "should not match up non-same-sex photos with same-sex photos" do
        guy_combos = Combinator.new_combos(@guy, 10)
        guy_combos.only.other_photo(@guy).should == @girl
      end
    end
  end

  describe "restock_all" do
    it "should create more matches if necessary" do
      2.times do
        Factory.create(:female_photo)
      end

      ActiveRecord::Observer.with_observers(:combo_observer) do
        new_photo = Factory(:male_photo, :player => Factory(:registered_player))
        new_photo.user.update_attribute(:last_request_at, 1.day.ago)

        new_photo.active_combos.count.should == 0
        new_photo.combos_needed.should == 2

        Combinator.restock_all

        new_photo.reload
        new_photo.active_combos.count.should == 2

        new_photo.combos_needed.should == 0
      end
    end

  end
end
