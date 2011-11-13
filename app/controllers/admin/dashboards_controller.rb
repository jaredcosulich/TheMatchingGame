class Admin::DashboardsController < AdminController

  def index
    time_frame = params.include?(:hours) ? params[:hours].to_i.hours : 1.day
    @rolling_day                = Admin::Snapshot.new(Time.now, time_frame).report
    @rolling_day_one_week_ago   = Admin::Snapshot.new(7.days.ago, time_frame).report
    @rolling_day_four_weeks_ago = Admin::Snapshot.new(28.days.ago, time_frame).report

    unless params.include?(:no_week)
      @rolling_week                = Admin::Snapshot.new(Time.now, 1.week).report
      @rolling_week_one_week_ago   = Admin::Snapshot.new(7.days.ago, 1.week).report
      @rolling_week_four_weeks_ago = Admin::Snapshot.new(28.days.ago, 1.week).report
    end
  end

  def matching
    @rolling_week_one_week_ago = Admin::MatchingPerformance.new(14.days.ago, 1.week).report
    @rolling_week_two_weeks_ago = Admin::MatchingPerformance.new(21.days.ago, 1.week).report
    @rolling_week_three_weeks_ago = Admin::MatchingPerformance.new(28.days.ago, 1.week).report
    @rolling_week_four_weeks_ago = Admin::MatchingPerformance.new(35.days.ago, 1.week).report
  end

  def analytics
    Garb::Session.login('services@irrationaldesign.com', 'thud5loop')
    profile = Garb::Profile.first('UA-15570848-1')

    results = Admin::BounceRate.results(profile, :start_date => 6.weeks.ago, :end_date => Date.today).reverse

    @bounce_rates = {}

    @bounce_rates[:rolling_day]                 = results.first.bounces.to_i * 100 / results.first.visits.to_i rescue "n/a"
    @bounce_rates[:rolling_day_one_week_ago]    = results[7].bounces.to_i * 100 / results[7].visits.to_i rescue "n/a"
    @bounce_rates[:rolling_day_four_weeks_ago]  = results[28].bounces.to_i * 100 / results[28].visits.to_i rescue "n/a"
    @bounce_rates[:rolling_week]                = sum(results, 0, 7, :bounces) * 100 / sum(results, 0, 7, :visits)
    @bounce_rates[:rolling_week_one_week_ago]   = sum(results, 7, 14, :bounces) * 100 / sum(results, 7, 14, :visits)
    @bounce_rates[:rolling_week_four_weeks_ago] = sum(results, 28, 35, :bounces) * 100 / sum(results, 28, 35, :visits)

    render :template => "admin/dashboards/analytics", :layout => false
  end

  protected
  def sum(arr, from, to, field)
    arr[from...to].inject(0){|total, row|total + row.send(field).to_i}
  end

end

