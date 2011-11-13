module AnswersHelper
  def counts(category)
    content_tag("span",  "(#{@counts[category]})", :class => "explanation")
  end
end
