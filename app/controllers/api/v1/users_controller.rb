class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: %i[show update destroy]
  skip_before_action :authenticate_user!, only: :create

  def index
    @users = policy_scope(User.includes(bicycles: :chain))
    render json: @users, each_serializer: ::Api::V1::UserSerializer, scope: :dashboard
  end

  def show
    authorize @user
    render json: @user, serializer: ::Api::V1::UserSerializer, scope: :dashboard
  end

  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created, serializer: ::Api::V1::UserSerializer
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @user
    if @user.update(user_params)
      render json: @user, serializer: ::Api::V1::UserSerializer
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user
    if @user.destroy
      head :no_content
    else
      render json: { error: "Failed to delete user" }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.includes(bicycles: :chain).find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
