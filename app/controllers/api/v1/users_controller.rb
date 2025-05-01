class Api::V1::UsersController < ApplicationController
  include Api::V1::CrudOperations
  skip_before_action :authenticate_user!, only: :create

  private

  def resource_class
    User
  end

  def resource_serializer
    ::Api::V1::UserSerializer
  end

  def resource_params
    params.require(:user).permit(:name, :email)
  end

  def find_resource
    resource_class.includes(:bicycles).find(params[:id])
  end
end
