class Api::Admin::MatchesController < ApplicationController
  def create
    next_number = (Match.maximum(:match_number) || 0) + 1
    @match = Match.new(match_params)
    @match.match_number = params[:match_number].present? ? params[:match_number].to_i : next_number
    @match.status = "upcoming"

    if @match.save
      render json: @match.as_json(include: {
        team1: { only: [:id, :name, :short_name] },
        team2: { only: [:id, :name, :short_name] }
      }), status: :created
    else
      render json: { errors: @match.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def calculate_points
    @match = Match.find(params[:id])
    PointsCalculator.new(@match).calculate_all!

    render json: {
      message: "Points calculated successfully",
      leaderboard: @match.match_entries.includes(:user).order(total_points: :desc).as_json(
        include: { user: { only: [:id, :name] } },
        only: [:id, :total_points]
      )
    }
  end

  def update_status
    @match = Match.find(params[:id])
    if @match.update(status: params[:status])
      render json: @match.as_json(methods: [:cricapi_match_id, :last_synced_at, :auto_sync])
    else
      render json: { errors: @match.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/admin/matches/:id/sync — manually trigger a sync from CricAPI
  def sync_match
    @match = Match.find(params[:id])
    syncer = MatchSyncService.new(@match)
    result = syncer.sync!

    render json: {
      success: result[:success],
      log: result[:log],
      performances: result[:performances] || 0,
      match: @match.reload.as_json(methods: [:cricapi_match_id, :last_synced_at, :auto_sync])
    }
  end

  # POST /api/admin/matches/:id/toggle_auto_sync
  def toggle_auto_sync
    @match = Match.find(params[:id])
    @match.update!(auto_sync: !@match.auto_sync)
    render json: {
      auto_sync: @match.auto_sync,
      message: @match.auto_sync ? "Auto-sync enabled (every 5 min)" : "Auto-sync disabled"
    }
  end

  # POST /api/admin/matches/:id/set_cricapi_id
  def set_cricapi_id
    @match = Match.find(params[:id])
    @match.update!(cricapi_match_id: params[:cricapi_match_id])
    render json: { cricapi_match_id: @match.cricapi_match_id, message: "CricAPI ID updated" }
  end

  private

  def match_params
    params.permit(:team1_id, :team2_id, :match_date, :venue, :match_number)
  end
end
