module Admin::DashboardsHelper
  def row(title, k1, k2, format=nil)
    row = ""
    row << content_tag(:td, title)
    [@rolling_day, @rolling_day_one_week_ago, @rolling_day_four_weeks_ago, @rolling_week, @rolling_week_one_week_ago, @rolling_week_four_weeks_ago].each do |report|
      next if report.nil?
      row << content_tag(:td, formatted(report[k1][k2], format))
    end
    row.html_safe
  end

  def matches_row(title, k1, k2, format=nil)
    row = ""
    row << content_tag(:td, title)
    [@rolling_week_one_week_ago, @rolling_week_two_weeks_ago, @rolling_week_three_weeks_ago, @rolling_week_four_weeks_ago].each do |report|
      row << content_tag(:td, formatted(report[k1][k2], format))
    end
    row.html_safe
  end

  def formatted(value, format)
    "#{number_with_precision(value, :strip_insignificant_zeros => true)}#{format == :percent ? "%" : ""}"
  end
end
