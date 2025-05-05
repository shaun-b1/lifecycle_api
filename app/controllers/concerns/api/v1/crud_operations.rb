module Api::V1::CrudOperations
  extend ActiveSupport::Concern

  included do
    before_action :set_resource, only: %i[show update destroy]
  end

  def index
    @resources = policy_scope(resource_class.all).page(params[:page])

    response_data = Api::V1::ResponseService.paginated(
      @resources,
      { resource_type: resource_class.name.pluralize }
    )

    response_data[:json][:data] = ActiveModelSerializers::SerializableResource.new(
      @resources,
      each_serializer: resource_serializer
    ).as_json

    render response_data
  end

  def show
    authorize @resource

    response = Api::V1::ResponseService.success(
      ActiveModelSerializers::SerializableResource.new(@resource, serializer: resource_serializer).as_json,
      "#{resource_class.name} retrieved successfully"
    )

    render response
  end

  def create
    @resource = build_resource(resource_params)
    authorize @resource if defined?(authorize)

    if @resource.save
      response_data = Api::V1::ResponseService.created(
        ActiveModelSerializers::SerializableResource.new(@resource, serializer: resource_serializer).as_json,
        "#{resource_class.name} created successfully"
      )
      render response_data
    else
      raise Api::V1::Errors::ValidationError.new(
        "Failed to create #{resource_class.name.downcase}",
        @resource.errors.full_messages
      )
    end
  end

  def update
    authorize @resource

    if @resource.update(resource_params)
     response_data = Api::V1::ResponseService.updated(
        ActiveModelSerializers::SerializableResource.new(@resource, serializer: resource_serializer).as_json,
        "#{resource_class.name} updated successfully"
      )
      render response_data
    else
      raise Api::V1::Errors::ValidationError.new(
        "Failed to update #{resource_class.name.downcase}",
        @resource.errors.full_messages
      )
    end
  end

  def destroy
    authorize @resource
    @resource.destroy

    response_data = Api::V1::ResponseService.deleted(
      "#{resource_class.name} deleted successfully"
    )
    render response_data
  end

  private

  def resource_class
    raise NotImplementedError, "#{self.class} must implement resource_class"
  end

  def resource_serializer
    raise NotImplementedError, "#{self.class} must implement resource_serializer"
  end

  def resource_params
    raise NotImplementedError, "#{self.class} must implement resource_params"
  end

  def set_resource
    @resource = find_resource
    rescue ActiveRecord::RecordNotFound
      raise Api::V1::Errors::ResourceNotFoundError.new(resource_class.name)
  end

  def find_resource
    resource_class.find(params[:id])
  end

  def build_resource(attributes)
    resource_class.new(attributes)
  end
end
