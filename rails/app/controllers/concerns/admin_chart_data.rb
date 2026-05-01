module AdminChartData
  private

  CHART_ICONS = {
    "subscribers" => "👥",
    "signups_per_day" => "📅",
    "signups_per_week" => "🗓️",
    "total_users" => "📈",
  }.freeze

  def fill_missing_dates(raw_hash)
    start_date = Date.parse(USERS_EPOCH)
    end_date   = Date.today
  
    (start_date..end_date).map do |date|
      [date.to_s, raw_hash[date] || 0]
    end
  end

  def fill_subscriber_timeline(subs)
    start_date = Date.parse(SUBSCRIBERS_EPOCH)
    end_date   = Date.today
  
    (start_date..end_date).map do |day|
      active = subs.count { |s| s.created_at.to_date <= day && s.current_period_end.to_date >= day }
      [day.to_s, active]
    end
  end

  def chart_data_subscribers
    subs = Pay::Subscription
             .where.not(status: "canceled")
             .where("created_at <= ?", Date.today)
             .select(:created_at, :current_period_end)
  
    fill_subscriber_timeline(subs)
  end

  def chart_data_signups_per_day
    raw = User.signed_in_more_than(0)
              .where("created_at >= ?", USERS_EPOCH)
              .group(Arel.sql("DATE(created_at)"))
              .order(Arel.sql("DATE(created_at)"))
              .count
  
    fill_missing_dates(raw)
  end

  
  def fill_missing_weeks_normalized(raw_hash)
    # Normalize keys to Date (beginning of week)
    normalized = raw_hash.transform_keys { |k| k.to_date.beginning_of_week }
  
    start_week = Date.parse(USERS_EPOCH).beginning_of_week
    end_week   = Date.today.beginning_of_week
  
    (start_week..end_week).step(7).map do |week|
      [week.to_s, normalized[week] || 0]
    end
  end

  def chart_data_signups_per_week
    raw = User.signed_in_more_than(0)
              .where("created_at >= ?", USERS_EPOCH)
              .group(Arel.sql("DATE_TRUNC('week', created_at)"))
              .order(Arel.sql("DATE_TRUNC('week', created_at)"))
              .count
  
    fill_missing_weeks_normalized(raw)
  end

  def chart_data_total_users
    raw = User.signed_in_more_than(1)
              .where("created_at >= ?", USERS_EPOCH)
              .group(Arel.sql("DATE(created_at)"))
              .order(Arel.sql("DATE(created_at)"))
              .count
  
    fill_missing_dates(raw)
  end

  KNOWN_CHARTS = %w[
    subscribers
    signups_per_day
    signups_per_week
    total_users
  ].freeze

  DEFAULT_CHART = KNOWN_CHARTS.first

  # Make these both on a Sunday so the X-axis rendering matches the data better
  USERS_EPOCH = '2026-01-04'
  SUBSCRIBERS_EPOCH = '2025-01-11'

  #---------------------------------------------------------------------------

  def chart_data(chart_param)
    chart_name = KNOWN_CHARTS.include?(chart_param) ? chart_param : DEFAULT_CHART
  
    {
      name: chart_name,
      title: I18n.t("admin.charts.#{chart_name}", default: chart_name.titleize),
      data: send("chart_data_#{chart_name}"),
    }
  end

  # "FIXME: This could probably be implemented using a single grouped
  # db query rather than doing a separate query for each interval"
  # Legacy helper (no longer used).
  # Chart data is now generated via optimized grouped SQL queries + zero-fill.
  # Not needed elsewhere.
  # 
  # def day_range(...)

end
