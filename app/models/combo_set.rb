class ComboSet
  attr_accessor :target_length

  def initialize(target_length)
    self.target_length = target_length
    @combos = []
    @extras = []
    @seen_player_ids = {}
    @seen_photo_ids = {}
  end

  def target_combos
    @combos
  end

  def combos
    (@combos + @extras)[0..target_length-1]
  end

  def full?
    length >= @target_length    
  end
  
  def empty?
    length == 0
  end

  def length
    @combos.length + @extras.length
  end

  def add(target)
    if @combos.length < @target_length
      new_combos = yield
      added_count = 0

      while(new_combo = new_combos.shift)
        unless seen_already?(new_combo)
          if added_count < target.round
            @combos << new_combo
          else
            @extras << new_combo
          end
          added_count += 1
        end
      end
    end
  end

  def seen_already?(combo)
    if @seen_player_ids[combo.photo_one.player_id].present? || @seen_player_ids[combo.photo_two.player_id].present? ||
       @seen_photo_ids[combo.photo_one_id].present? || @seen_photo_ids[combo.photo_two_id].present?
      true
    else
      @seen_player_ids[combo.photo_one.player_id] = combo unless combo.photo_one.player_id == 0
      @seen_player_ids[combo.photo_two.player_id] = combo unless combo.photo_two.player_id == 0
      @seen_photo_ids[combo.photo_one_id] = combo
      @seen_photo_ids[combo.photo_two_id] = combo
      false
    end
  end

end
