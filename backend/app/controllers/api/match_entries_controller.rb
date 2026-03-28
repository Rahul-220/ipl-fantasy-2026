class Api::MatchEntriesController < ApplicationController
  def index
    @match = Match.find(params[:match_id])
    @entries = @match.match_entries.includes(:user, :captain, :vice_captain, :selected_players)
    match_started = @match.started?
    current_user_id = params[:user_id].present? ? params[:user_id].to_i : nil

    entries_json = @entries.map do |entry|
      base = {
        id: entry.id,
        total_points: entry.total_points,
        user: { id: entry.user.id, name: entry.user.name }
      }

      if match_started || entry.user_id == current_user_id
        base[:captain] = entry.captain ? { id: entry.captain.id, name: entry.captain.name } : nil
        base[:vice_captain] = entry.vice_captain ? { id: entry.vice_captain.id, name: entry.vice_captain.name } : nil
        base[:selected_players] = entry.selected_players.as_json(only: [:id, :name, :role])
        base[:team_visible] = true
      else
        base[:captain] = nil
        base[:vice_captain] = nil
        base[:selected_players] = []
        base[:team_visible] = false
      end

      base
    end

    render json: entries_json
  end

  def create
    @match = Match.find(params[:match_id])

    if @match.started?
      return render json: { error: "Cannot join a match that has already started or completed" }, status: :unprocessable_entity
    end

    user = User.find(params[:user_id])
    player_ids = params[:player_ids] || []

    if player_ids.length != 11
      return render json: { error: "Must select exactly 11 players" }, status: :unprocessable_entity
    end

    # Validate all players belong to one of the two match teams
    valid_player_ids = @match.players.pluck(:id)
    invalid = player_ids.map(&:to_i) - valid_player_ids
    if invalid.any?
      return render json: { error: "Some selected players don't belong to either team: #{invalid}" }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      @entry = @match.match_entries.create!(user: user)

      player_ids.each do |pid|
        @entry.team_selections.create!(ipl_player_id: pid)
      end

      if params[:captain_id].present?
        @entry.update!(captain_id: params[:captain_id])
      end

      if params[:vice_captain_id].present?
        @entry.update!(vice_captain_id: params[:vice_captain_id])
      end
    end

    render json: @entry.as_json(
      include: {
        user: { only: [:id, :name] },
        selected_players: { only: [:id, :name, :role] }
      }
    ), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def show
    @entry = MatchEntry.includes(:user, :captain, :vice_captain, :selected_players).find(params[:id])
    render json: @entry.as_json(
      include: {
        user: { only: [:id, :name] },
        captain: { only: [:id, :name] },
        vice_captain: { only: [:id, :name] },
        selected_players: { only: [:id, :name, :role], include: { ipl_team: { only: [:id, :short_name] } } }
      }
    )
  end

  def destroy
    @match = Match.find(params[:match_id])
    @entry = @match.match_entries.find(params[:id])

    if @match.started?
      return render json: { error: "Cannot withdraw after match has started" }, status: :unprocessable_entity
    end

    @entry.destroy
    render json: { message: "Entry withdrawn successfully" }
  end
end
