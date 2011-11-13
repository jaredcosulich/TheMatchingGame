class CoupleFriend < ActiveRecord::Base
  belongs_to :combo

    scope :for_combo, lambda { |combo|
    {
      :conditions => ["combo_id=? OR other_combo_id=?", combo.id, combo.id]
    }
  }

  def self.find_or_create_by_combo_ids(combo_1_id, combo_2_id)
    existing = CoupleFriend.find(:first, :conditions => ["(combo_id=? AND other_combo_id=?) OR (combo_id=? AND other_combo_id=?)", combo_1_id, combo_2_id, combo_2_id, combo_1_id])
    return existing unless existing.nil?
    create(:combo_id => combo_1_id, :other_combo_id => combo_2_id)
  end

  def other_combo(combo)
    Combo.find([combo_id, other_combo_id].detect { |combo_id| combo_id != combo.id })
  end

  def self.already_friended?(player, combo)
    !self.for_combo(combo).find(:all, :include => {:combo => :photo_one}).detect { |c| c.other_combo(combo).photo_one.player_id == player.id }.nil?
  end
end
