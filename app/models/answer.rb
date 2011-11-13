class Answer < ActiveRecord::Base
  before_create :set_kind
  belongs_to :game
  belongs_to :player
  belongs_to :combo
  after_create :add_to_combo

  scope :combo_ids, select("combo_id")

  scope :limited, limit(20).order("answers.id desc")
  scope :offset, lambda { |offset| offset(offset) }

  scope :yes, where("answer = 'y'")
  scope :no, where("answer = 'n'")

  scope :full, includes({:combo => [:combo_scores, :photo_one, :photo_two, :response]})

  scope :active_combos, where("combos.active = true")
  scope :inactive_combos, where("combos.active = false")

  scope :good, where("combos.yes_percent >= 75")
  scope :possible, where("combos.yes_percent BETWEEN 55 AND 75")
  scope :bad, where("combos.yes_percent < 55")

  scope :existing, where("kind='existed'")
  scope :predicted, where("kind='predicted'")
  scope :not_predicted, where("kind!='predicted'")
  scope :not_fake_predicted, where("kind!='fake_predicted'")

  scope :predicted_with_response_since, lambda { |since|
   where("kind='predicted' AND responses.updated_at > '#{since}'")
  }

  scope :inactivated_since, lambda { |since|
    full.where("combos.inactivated_at > '#{since}'")
  }

  scope :both_positive, where("responses.photo_one_answer != 'bad' and photo_one_answer is not null and photo_two_answer != 'bad' and photo_two_answer is not null")
  scope :both_negative, where("responses.photo_one_answer = 'bad' and photo_two_answer = 'bad'")
  scope :one_positive,  where("(responses.photo_one_answer != 'bad' and photo_one_answer is not null and photo_two_answer is null) OR (photo_two_answer != 'bad' and photo_two_answer is not null and photo_one_answer is null)")
  scope :one_negative,  where("(responses.photo_one_answer = 'bad' and photo_two_answer is null) OR (photo_two_answer = 'bad' and photo_one_answer is null)")
  scope :conflicting,   where("(responses.photo_one_answer != 'bad' and photo_two_answer = 'bad') OR (photo_two_answer != 'bad' and photo_one_answer = 'bad')")

  scope :any_negative, where("responses.photo_one_answer = 'bad' OR responses.photo_two_answer = 'bad'")

  scope :duplicate, joins({:game => :player}).select("player_id, combo_id, count(*) as count").group("player_id, combo_id").having("count(*) > 1").order("count(*) DESC")

  scope :unread, full.where("answers.viewed_at < combos.state_changed_at")

  scope :correct, includes({:combo => :response}).where("(answer = 'n' AND (responses.photo_one_answer = 'bad' OR photo_two_answer = 'bad')) OR (answer = 'y' AND photo_one_answer in ('good', 'interested', 'uninterested') AND photo_two_answer in ('good', 'interested', 'uninterested'))")
  scope :incorrect, includes({:combo => :response}).where("(answer = 'y' AND (responses.photo_one_answer = 'bad' OR photo_two_answer = 'bad')) OR (answer = 'n' AND photo_one_answer in ('good', 'interested', 'uninterested') AND photo_two_answer in ('good', 'interested', 'uninterested'))")
  scope :correct_or_incorrect, includes({:combo => :response}).where("(responses.photo_one_answer = 'bad' OR photo_two_answer = 'bad') OR (photo_one_answer in ('good', 'interested', 'uninterested') AND photo_two_answer in ('good', 'interested', 'uninterested'))")

  scope :good_introductions, lambda {
    joins({:combo => :response}).
      order("answers.id desc").
      where("answers.answer = 'y' AND (responses.photo_one_answer in ('good', 'interested', 'uninterested') AND responses.photo_two_answer in ('good', 'interested', 'uninterested'))")
  }

  scope :bad_introductions, lambda {
    joins({:combo => :response}).
      order("answers.id desc").
      where("answers.answer = 'y' AND (responses.photo_one_answer = 'bad' AND responses.photo_two_answer = 'bad')")
  }

  scope :potential_introductions, lambda {
    includes({:combo => :response}).
      order("answers.id desc").
      where("answers.answer = 'y' AND responses.id is null")
  }

  def <=>(other)
    id <=> other.id
  end

  def include?(photo)
    [combo.photo_one, combo.photo_two].include?(photo)
  end

  def full_answer
    answer =~ /y/ ? "Yes" : "No"
  end

  def yes?
    answer =~ /y/
  end

  def correct?
    (combo.verified_good? && answer =~ /y/ ) || (combo.verified_bad? && answer =~ /n/ )
  end

  def incorrect?
    (combo.verified_good? && answer =~ /n/ ) || (combo.verified_bad? && answer =~ /y/ )
  end

  def existing_correct?
    correct? && existed?
  end

  def existing_incorrect?
    incorrect? && existed?
  end

  def verified?
    correct? || incorrect?
  end

  def set_kind
    return unless player.present?
    self.kind = combo.fake_predicted? ? "fake_predicted" : (combo.verified? ? "existed" : "predicted")
  end

  def existed?
    kind == "existed"
  end

  def predicted?
    kind == "predicted" || kind == "fake_predicted"
  end

  def self.set_viewed_at(answers)
    connection.execute("update answers set viewed_at = '#{Time.new.utc}' where id in (#{answers.map(&:id).join(',')});")
  end

  def add_to_combo
    Answer.set_viewed_at([self])
    combo.add_answer(answer)
  end
end
