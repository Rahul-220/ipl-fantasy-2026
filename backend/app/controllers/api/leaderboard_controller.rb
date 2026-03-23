class Api::LeaderboardController < ApplicationController
  def index
    # Aggregate total points per user across all completed matches
    user_points = MatchEntry
      .joins(:match, :user)
      .where(matches: { status: "completed" })
      .group("users.id", "users.name")
      .select("users.id as user_id, users.name as user_name, SUM(match_entries.total_points) as total_points, COUNT(match_entries.id) as matches_played")
      .order("total_points DESC")

    render json: user_points.map { |up|
      {
        user_id: up.user_id,
        user_name: up.user_name,
        total_points: up.total_points.to_f,
        matches_played: up.matches_played
      }
    }
  end
end
