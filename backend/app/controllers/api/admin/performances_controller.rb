class Api::Admin::PerformancesController < ApplicationController
  def index
    @match = Match.find(params[:match_id])
    @performances = @match.player_match_performances.includes(:ipl_player)
    render json: @performances.as_json(
      include: { ipl_player: { only: [:id, :name, :role], include: { ipl_team: { only: [:id, :short_name] } } } }
    )
  end

  def create
    @match = Match.find(params[:match_id])
    @performance = @match.player_match_performances.find_or_initialize_by(ipl_player_id: params[:ipl_player_id])

    if @performance.update(performance_params)
      render json: @performance.as_json(
        include: { ipl_player: { only: [:id, :name, :role] } }
      ), status: :ok
    else
      render json: { errors: @performance.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @performance = PlayerMatchPerformance.find(params[:id])

    if @performance.update(performance_params)
      render json: @performance.as_json(
        include: { ipl_player: { only: [:id, :name, :role] } }
      )
    else
      render json: { errors: @performance.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def performance_params
    params.permit(
      :runs_scored, :balls_faced, :fours, :sixes, :is_duck, :did_bat,
      :overs_bowled, :maidens, :runs_conceded, :wickets, :lbw_bowled_count,
      :catches, :stumpings, :direct_run_outs, :indirect_run_outs
    )
  end
end
