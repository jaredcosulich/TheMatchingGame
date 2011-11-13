class ComboActionObserver < ActiveRecord::Observer
  def after_create(combo_action)
    PhotoPair.delay(:priority => 9).refresh_by_combo_id(combo_action.combo_id)
  end
end

