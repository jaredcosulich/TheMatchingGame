class ComboObserver < ActiveRecord::Observer

  def after_create(combo)
    PhotoPair.create_or_refresh_by_combo(combo)
  end

  def after_save(combo)
    ComboScore.create_or_update_for_combo(combo) if combo.active?
    PhotoPair.delay(:priority => 9).refresh_by_combo_id(combo.id)

    if combo.couple_combo? && combo.couple_complete?
      Emailing.delay(:priority => 7).deliver("couple_complete", combo.photo_one.player.user.id, combo.id)
      CoupleFriend.for_combo(combo).collect { |cf| cf.other_combo(combo) }.each do |c|
        Emailing.delay(:priority => 7).deliver("couple_complete", c.photo_one.player.user.id, combo.id)
      end
    end
  end

  def before_save(combo)
    check_votes(combo)
    if !combo.active? && combo.active_was
      combo.inactivated_at = Time.new
      combo.state_changed_at = combo.inactivated_at
    end
    true
  end

  def check_votes(combo)
    if combo.active? && !combo.couple_combo?
      if combo.college_id.present?
        if combo.yes_count + combo.no_count >= 7
          combo.build_response(:creation_reason => "college_total") if combo.response.nil?
          combo.active = false
        end
      else
        if combo.yes_count >= 4 && combo.yes_percent > 55
          combo.build_response(:creation_reason => "combo_yes") if combo.response.nil?
        end

        if combo.yes_count >= 4 || combo.no_count >= 3 || (combo.no_count >= 2 && combo.yes_percent < 40)
          combo.active = false
        end
      end
    end
  end
end
