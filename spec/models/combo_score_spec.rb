require 'spec_helper'

describe ComboScore do
  describe "generate_all" do
    it "should clean up existing scores and not rescore invalid combos" do
      valid_combo = Factory(:combo)
      invalid_combo = Factory(:combo)
      invalid_combo.photo_one.update_attribute(:gender, invalid_combo.photo_two.gender)
      will_become_invalid_combo = Factory(:combo)

      ComboScore.generate_all
      ComboScore.count.should == 4


      will_become_invalid_combo.photo_one.update_attribute(:gender, invalid_combo.photo_two.gender)
      ComboScore.generate_all

      ComboScore.count.should == 2
      ComboScore.all.collect(&:combo_id).should == [valid_combo.id, valid_combo.id]
    end
  end
end
