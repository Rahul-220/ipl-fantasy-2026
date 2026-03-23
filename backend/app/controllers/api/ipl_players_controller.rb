class Api::IplPlayersController < ApplicationController
  def index
    @players = IplPlayer.includes(:ipl_team)
    @players = @players.where(ipl_team_id: params[:team_id]) if params[:team_id]
    @players = @players.order(:name)
    render json: @players.as_json(include: { ipl_team: { only: [:id, :name, :short_name] } })
  end

  def create
    @player = IplPlayer.new(player_params)
    if @player.save
      render json: @player.as_json(include: { ipl_team: { only: [:id, :name, :short_name] } }), status: :created
    else
      render json: { errors: @player.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @player = IplPlayer.find(params[:id])
    if @player.update(player_params)
      render json: @player.as_json(include: { ipl_team: { only: [:id, :name, :short_name] } })
    else
      render json: { errors: @player.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @player = IplPlayer.find(params[:id])
    @player.destroy
    render json: { message: "Player deleted successfully" }
  end

  private

  def player_params
    params.permit(:name, :ipl_team_id, :role)
  end
end
