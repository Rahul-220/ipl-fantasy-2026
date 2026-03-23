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

    @match.match_entries.includes(:team_selections, :captain, :vice_captain).each do |entry|
      total = 0.0

      entry.team_selections.each do |selection|
        perf = PlayerMatchPerformance.find_by(match_id: @match.id, ipl_player_id: selection.ipl_player_id)
        next unless perf

        points = perf.fantasy_points.to_f

        if entry.captain_id == selection.ipl_player_id
          points *= 2.0
        elsif entry.vice_captain_id == selection.ipl_player_id
          points *= 1.5
        end

        total += points
      end

      entry.update!(total_points: total)
    end

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
      render json: @match
    else
      render json: { errors: @match.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def match_params
    params.permit(:team1_id, :team2_id, :match_date, :venue, :match_number)
  end
end
