require 'spec_helper'

describe ComboActionObserver do

  it "should refresh the photo pair" do
    combo = Factory.create(:combo)
    Factory(:user, :player => combo.photo_two.player)
    PhotoPair.create_or_refresh_by_combo(combo)

    ActiveRecord::Observer.with_observers(:combo_action_observer) do
      PhotoPair.should_receive(:refresh_by_combo_id).with(combo.id)

      combo.connect(combo.photo_one, "hi")
      work_all_jobs
    end
  end

end

