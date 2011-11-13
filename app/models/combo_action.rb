class ComboAction < ActiveRecord::Base
  belongs_to :combo
  belongs_to :photo

  validate :check_connected
  after_create :debit_connection
  after_create :notify_other

  default_scope :order => "created_at asc"
  scope :full, order("created_at asc").includes(:photo)
  scope :messages, where("action = 'message'")
  scope :not_messages, where("action != 'message'")
  scope :connects_and_messages, where("action = 'message' OR action = 'connect'")

  CREDITS_TO_CONNECT = 20
  CONVERSATION_PRICE = 2
  SUBSCRIPTION_PRICE = 5

  def unread?(player)
    photo.player != player && viewed_at.nil?
  end

  def other_photo
    combo.other_photo(photo)
  end

  def other_actor
    other_photo.player
  end

  def actor
    photo.player
  end

  def actor?(player)
    photo.player_id == player.id
  end

  def visible_to?(player)
    return true
    player == actor || player.subscribed? || combo.unlocked_for?(player)
  end

  def debit_connection
    return true
    return unless ['connect', 'cancel'].include?(action)
    amount = case action
      when "connect" : -CREDITS_TO_CONNECT
      when "cancel" : CREDITS_TO_CONNECT
      else 0
    end
    user = photo.player.user
    user.transactions.create(:source => self, :amount => amount)
  end

  def notify_other
    Emailing.delay(:priority => 1).deliver("combo_action_notification", other_actor.user.id, id) unless action == 'cancel'
  end

  def check_connected
    combo_connected = combo.connected?
    reciprocated = combo.reciprocated?
    valid =  case action
      when "message": combo_connected
      when "cancel": combo_connected && !reciprocated
      when "connect": !combo_connected
      else false
    end
    errors.add_to_base("#{combo_connected ? "Connected" : "Not connected"} and #{reciprocated ? "reciprocated" : "Not reciprocated"} is not a valid state for #{action}") unless valid
  end

  def self.unread_message_count(player)
    photo_ids = player.photos.map(&:id).join(", ")
    return 0 if photo_ids.blank?
    unread_sql = <<-sql
      select count(*)
      from combo_actions, photo_pairs
      where combo_actions.photo_id not in (#{photo_ids}) and
            combo_actions.combo_id = photo_pairs.combo_id and
            photo_pairs.photo_id in (#{photo_ids}) and
            combo_actions.viewed_at is null
    sql
    ComboAction.connection.select_value(unread_sql).to_i
  end
end
