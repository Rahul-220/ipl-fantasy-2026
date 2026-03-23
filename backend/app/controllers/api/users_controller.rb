class Api::UsersController < ApplicationController
  def index
    @users = User.all.order(:name)
    render json: @users
  end

  def create
    @user = User.find_or_create_by(name: params[:name])
    if @user.persisted?
      render json: @user, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
