class Question < ActiveRecord::Base
  include Permalinkable
  validates_presence_of :title

  has_many :question_answers
  belongs_to :player

  after_create :notify_admin

  scope :popular, lambda {
    popular_ids = Question.connection.select_values("select question_id, count(*) from question_answers group by 1 order by 2 desc")
    where("id in (#{popular_ids.join(',')})")
  }

  scope :not_in, lambda { |ids|
    return nil if ids.blank?
    where("questions.id not in (#{ids})")
  }

  scope :recent, order("created_at desc")
  scope :alphabetic, order("title asc")
  scope :unverified, where("verified = false")

  def popular_answers
    popular_answers = question_answers.select("answer, count(*) as count").group("answer").order("count desc").map(&:answer)
    popular_answers += suggested_answers.split(",").map(&:strip)
    popular_answers.uniq[0...10]
  end

  def grouped_opposite_sex_answers(gender)
    opposite_sex_answers(gender).
      inject(Hash.new(0)) { |grouped, a| grouped[a.answer] += 1; grouped }.
      to_a.sort { |a,b| b[1] <=> a[1] }
  end

  def opposite_sex_answers(gender)
    question_answers.select { |a| a.player.gender != gender}
  end

  def notify_admin
    AdminMailer.delay(:priority => 9).deliver_notify("New Question", "A question was created", :question => self)
  end
end
