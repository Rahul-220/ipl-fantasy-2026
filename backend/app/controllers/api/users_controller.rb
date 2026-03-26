class Api::UsersController < ApplicationController
  def index
    @users = User.all.order(:name)
    render json: @users.map { |u| { id: u.id, name: u.name } }
  end

  def create
    @user = User.new(name: params[:name], password: params[:password])
    if @user.save
      render json: { id: @user.id, name: @user.name }, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    @user = User.find_by(name: params[:name])
    if @user&.authenticate(params[:password])
      render json: { id: @user.id, name: @user.name }
    else
      render json: { error: "Invalid name or password" }, status: :unauthorized
    end
  end
end
