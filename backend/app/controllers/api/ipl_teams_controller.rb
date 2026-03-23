class Api::IplTeamsController < ApplicationController
  def index
    @teams = IplTeam.all.order(:name)
    render json: @teams.as_json(methods: [:players_count])
  end

  def show
    @team = IplTeam.find(params[:id])
    @players = @team.ipl_players.order(:role, :name)
    render json: {
      team: @team,
      players: @players
    }
  end
end
