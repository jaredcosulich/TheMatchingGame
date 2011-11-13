require 'spec_helper'

describe ComboSet do
  it "should collect combos in subsets" do
    combo_one = Factory.create(:combo)
    combo_two = Factory.create(:combo)
    combo_three = Factory.create(:combo)

    combo_set = ComboSet.new(10)
    combo_set.add(1){[combo_one]}
    combo_set.add(2){[combo_two, combo_three]}

    combo_set.combos.sort.should == [combo_one, combo_two, combo_three]
  end

  it "should ignore duplicate combos in different subsets" do
    combo_one = Factory.create(:combo)
    combo_two = Factory.create(:combo)
    combo_three = Factory.create(:combo)

    combo_set = ComboSet.new(10)
    combo_set.add(2){[combo_one, combo_two]}
    combo_set.add(2){[combo_two, combo_three]}

    combo_set.combos.sort.should == [combo_one, combo_two, combo_three]
  end

  it "should not call the block if full" do
    combo_one = Factory.create(:combo)
    combo_two = Factory.create(:combo)

    combo_set = ComboSet.new(2)
    combo_set.add(2){[combo_one, combo_two]}
    combo_set.add(2){raise "don't call me!"}

    combo_set.combos.sort.should == [combo_one, combo_two]    
  end
  
  it "should know if it is full" do
    combo_one = Factory.create(:combo)
    combo_two = Factory.create(:combo)
    combo_three = Factory.create(:combo)

    combo_set = ComboSet.new(3)

    combo_set.add(1){[combo_one]}
    combo_set.should_not be_full
    combo_set.combos.length.should_not == 3

    combo_set.add(1){[combo_two, combo_three]}
    combo_set.should be_full
    combo_set.combos.length.should == 3
  end

  it "should use the target length on each add call" do
    combo_one = Factory.create(:combo)
    combo_two = Factory.create(:combo)
    combo_three = Factory.create(:combo)

    combo_set = ComboSet.new(2)
    combo_set.add(1){[combo_one, combo_two]}
    combo_set.add(1){[combo_three]}

    combo_set.combos.sort.should == [combo_one, combo_three]
  end

  it "should keep track of extras above the target subset length and use them if necessary" do
    combo_one = Factory.create(:combo)
    combo_two = Factory.create(:combo)
    combo_three = Factory.create(:combo)

    combo_set = ComboSet.new(3)
    combo_set.add(1){[combo_one]}
    combo_set.add(1){[combo_two, combo_three]}

    combo_set.combos.sort.should == [combo_one, combo_two, combo_three]    
  end

  it "should skip seen photos" do
    combo_one = Factory.create(:combo)
    combo_two = Factory.create(:combo, :photo_one => combo_one.photo_one)
    combo_three = Factory.create(:combo)

    combo_set = ComboSet.new(3)
    combo_set.add(3){[combo_one, combo_two, combo_three]}

    combo_set.combos.sort.should == [combo_one, combo_three]    
  end
  
  it "should skip seen users" do
    combo_one = Factory.create(:combo)
    combo_two = Factory.create(:combo, :photo_one => Factory.create(:male_photo, :player => combo_one.photo_one.player))
    combo_three = Factory.create(:combo, :photo_two => Factory.create(:female_photo, :player => combo_one.photo_two.player))
    combo_four = Factory.create(:combo)

    combo_set = ComboSet.new(5)
    combo_set.add(5){[combo_one, combo_two, combo_three, combo_four]}

    combo_set.combos.map(&:id).sort.should == [combo_one, combo_four].map(&:id)
  end

  it "should raise if no block given" do
    combo_set = ComboSet.new(5)
    lambda {combo_set.add(3)}.should raise_error
  end
end

