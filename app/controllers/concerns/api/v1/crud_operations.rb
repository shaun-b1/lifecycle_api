module Api::V1::CrudOperations
  extend ActiveSupport::Concern

  included do
    before_action :set_resource, only: %i[show update destroy]
  end

  def index
    @resources = policy_scope(resource_class.all)
    render json: @resources, each_serializer: resource_serializer
  end

  def show
    authorize @resource
    render json: @resource, serializer: resource_serializer
  end

  def create
    @resource = build_resource(resource_params)

    if @resource.save
      render json: @resource, status: :created, serializer: resource_serializer
    else
      handle_validation_error(@resource)
    end
  end

  def update
    authorize @resource
    if @resource.update(resource_params)
      render json: @resource, serializer: resource_serializer
    else
      handle_validation_error(@resource)
    end
  end

  def destroy
    authorize @resource
    @resource.destroy
    head :no_content
  end

  private

  def handle_validation_error
    render json: resource.errors, status: :unprocessable_entity
  end

  def resource_class
    User
  end

  def resource_serializer
    ::Api::V1::UserSerializer
  end

  def resource_params
    params.require(:user).permit(:name, :email)
  end

  def set_resource
    @resource = find_resource
  end

  def find_resource
    resource_class = resource_class.find(params[:id])
  end

  def build_resource(attributes)
    resource_class.new(attributes)
  end
end
