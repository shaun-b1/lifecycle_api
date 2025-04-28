class Api::V1::UsersController < ApplicationController
  include Api::V1::CrudOperations
  skip_before_action :authenticate_user!, only: :create
end
