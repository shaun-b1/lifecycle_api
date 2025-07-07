module ::Api::V1::ComponentManagement
  extend ActiveSupport::Concern

  included do
    before_action :set_bicycle
    before_action :set_component, only: %i[show update destroy]
  end

  def show
    authorize @component

    response = Api::V1::ResponseService.success(
      ActiveModelSerializers::SerializableResource.new(@component,
        serializer: component_serializer).as_json,
      "#{component_class.name} retrieved successfully"
    )

    render response
  end

  def create
    @component = build_component(component_params)
    authorize @component

    if @component.save
      response_data = Api::V1::ResponseService.created(
        ActiveModelSerializers::SerializableResource.new(@component,
          serializer: component_serializer).as_json,
        "#{component_class.name} created successfully"
      )

      render response_data
    else
      raise Api::V1::Errors::ValidationError.new(
        "Failed to create #{component_class.name}",
        @component.errors.full_messages
        )
    end
  end

  def update
    authorize @component

    if @component.update(component_params)
      response_data = Api::V1::ResponseService.updated(
        ActiveModelSerializers::SerializableResource.new(@component,
          serializer: component_serializer).as_json,
        "#{component_class.name} updated successfully"
      )
      render response_data
    else
      raise Api::V1::Errors::ValidationError.new(
        "Failed to update #{component_class.name}",
        @component.errors.full_messages
        )
    end
  end

  def destroy
    authorize @component
    @component.destroy

    response_data = Api::V1::ResponseService.deleted(
      "#{component_class.name} deleted successfully"
    )

    render response_data
  end

  private

  def set_bicycle
    @bicycle = Bicycle.find(params[:bicycle_id])
  rescue ActiveRecord::RecordNotFound
      raise Api::V1::Errors::ResourceNotFoundError.new(
        "Bicycle with ID #{params[:bicycle_id]} not found"
      )
  end

  def component_class
    raise NotImplementedError, "Subclasses must define component_class"
  end

  def component_serializer
    ::Api::V1::ComponentSerializer
  end

  def component_param_key
    component_class.to_s.underscore
  end

  def set_component
    @component = find_component
  rescue ActiveRecord::RecordNotFound
      raise Api::V1::Errors::ResourceNotFoundError.new(
        "#{component_class.name} with ID #{params[:id]} not found for Bicycle #{params[:bicycle_id]}"
      )
  end

  def find_component
    if single_component?
      component = @bicycle.send(component_class.to_s.underscore)
      raise ActiveRecord::RecordNotFound unless component
      component
    else
      @bicycle.send(component_class.to_s.pluralize.underscore).find(params[:id])
    end
  end

  def build_component(attributes)
    if single_component?
      @bicycle.send("build_#{component_class.to_s.underscore}", attributes)
    else
      @bicycle.send(component_class.to_s.pluralize.underscore).build(attributes)
    end
  end

  def component_params
    params.require(component_param_key).permit(:brand, :kilometres)
  rescue ActionController::ParameterMissing => e
      raise Api::V1::Errors::ParameterMissingError.new(component_param_key)
  end

  def single_component?
    @bicycle.respond_to?(component_class.to_s.underscore)
  end
end
