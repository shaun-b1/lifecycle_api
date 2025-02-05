class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: %i[ show update destroy ]

  def index
    @users = User.all
    render json: @users, each_serializer: ::Api::V1::UserSerializer
  end

  def show
    render json: @user, serializer: ::Api::V1::UserSerializer
  end

  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created, location: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.destroy
      head :no_content
    else
      render json: { error: "Failed to delete user" }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.includes(:bicycles).find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
