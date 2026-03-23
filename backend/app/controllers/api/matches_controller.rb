class Api::MatchesController < ApplicationController
  def index
    @matches = Match.includes(:team1, :team2).order(:match_date)
    render json: @matches.as_json(
      include: {
        team1: { only: [:id, :name, :short_name, :logo_url] },
        team2: { only: [:id, :name, :short_name, :logo_url] }
      },
      methods: [:full?]
    ).map { |m| m.merge("entries_count" => Match.find(m["id"]).match_entries.count) }
  end

  def show
    @match = Match.includes(:team1, :team2, match_entries: [:user, :captain, :vice_captain, :selected_players]).find(params[:id])
    players = @match.players.order(:name)
    match_started = @match.status != "upcoming"
    current_user_id = params[:user_id].present? ? params[:user_id].to_i : nil

    entries_json = @match.match_entries.map do |entry|
      base = {
        id: entry.id,
        total_points: entry.total_points,
        user: { id: entry.user.id, name: entry.user.name }
      }

      # Only show team details if match has started OR it's the current user's own entry
      if match_started || entry.user_id == current_user_id
        base[:captain] = entry.captain ? { id: entry.captain.id, name: entry.captain.name } : nil
        base[:vice_captain] = entry.vice_captain ? { id: entry.vice_captain.id, name: entry.vice_captain.name } : nil
        base[:selected_players] = entry.selected_players.map { |p|
          { id: p.id, name: p.name, role: p.role, ipl_team: { id: p.ipl_team_id, short_name: p.ipl_team.short_name } }
        }
        base[:team_visible] = true
      else
        base[:captain] = nil
        base[:vice_captain] = nil
        base[:selected_players] = []
        base[:team_visible] = false
      end

      base
    end

    render json: {
      match: @match.as_json(
        include: {
          team1: { only: [:id, :name, :short_name, :logo_url] },
          team2: { only: [:id, :name, :short_name, :logo_url] }
        }
      ),
      players: players.as_json(include: { ipl_team: { only: [:id, :name, :short_name] } }),
      entries: entries_json,
      entries_count: @match.match_entries.count,
      is_full: @match.full?
    }
  end

  def leaderboard
    @match = Match.find(params[:id])
    entries = @match.match_entries.includes(:user).order(total_points: :desc)

    render json: entries.as_json(
      include: { user: { only: [:id, :name] } },
      only: [:id, :total_points]
    )
  end
end
