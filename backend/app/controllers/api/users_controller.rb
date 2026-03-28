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

  # One-time endpoint to set passwords for legacy users
  def reset_passwords
    defaults = { "Naveen" => "naveen123", "Nithish" => "nithish123", "Rahul" => "rahul123" }
    updated = []
    defaults.each do |name, pwd|
      user = User.find_by(name: name)
      if user
        user.update!(password: pwd)
        updated << name
      end
    end
    render json: { message: "Passwords reset for: #{updated.join(', ')}" }
  end
end
