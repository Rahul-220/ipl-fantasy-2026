class Api::LeaderboardController < ApplicationController
  def index
    # Aggregate total points per user across all completed matches
    user_points = MatchEntry
      .joins(:match, :user)
      .where(matches: { status: "completed" })
      .group("users.id", "users.name")
      .select("users.id as user_id, users.name as user_name, SUM(match_entries.total_points) as total_points, COUNT(match_entries.id) as matches_played")
      .order("total_points DESC")

    # Also fetch per-match breakdown for each user
    match_entries_by_user = MatchEntry
      .joins(:match, :user)
      .joins("INNER JOIN ipl_teams t1 ON t1.id = matches.team1_id")
      .joins("INNER JOIN ipl_teams t2 ON t2.id = matches.team2_id")
      .where(matches: { status: "completed" })
      .select("match_entries.*, users.name as user_name, matches.match_number, matches.match_date, t1.short_name as team1_short, t2.short_name as team2_short")
      .order("matches.match_date ASC")

    breakdown_map = {}
    match_entries_by_user.each do |entry|
      breakdown_map[entry.user_id] ||= []
      breakdown_map[entry.user_id] << {
        match_id: entry.match_id,
        match_number: entry.match_number,
        match_label: "#{entry.team1_short} vs #{entry.team2_short}",
        match_date: entry.match_date,
        points: entry.total_points.to_f
      }
    end

    render json: user_points.map { |up|
      {
        user_id: up.user_id,
        user_name: up.user_name,
        total_points: up.total_points.to_f,
        matches_played: up.matches_played,
        match_breakdown: breakdown_map[up.user_id] || []
      }
    }
  end
end

