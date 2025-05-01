module ::Api::V1::ComponentManagement
  extend ActiveSupport::Concern

  included do
    before_action :set_bicycle
    before_action :set_component, only: %i[show update destroy]
  end

  def show
    authorize @component
    render json: @component, serializer: component_serializer
  end

  def create
    @component = build_component(component_params)
    authorize @component

    if @component.save
      render json: @component, status: :created, serializer: component_serializer
    else
      handle_validation_error(@component)
    end
  end

  def update
    authorize @component
    if @component.update(component_params)
      render json: @component, serializer: component_serializer
    else
      handle_validation_error(@component)
    end
  end

  def destroy
    authorize @component
    @component.destroy
    head :no_content
  end

  private

  def handle_validation_error(resource)
    error_messages = resource.errors.full_messages

    render json: {
      error: error_messages
    }, status: :unprocessable_entity
  end

  def set_bicycle
    @bicycle = Bicycle.find(params[:bicycle_id])
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
  end

  def find_component
    if single_component?
      @bicycle.send(component_class.to_s.underscore)
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
  end

  def single_component?
    @bicycle.respond_to?(component_class.to_s.underscore)
  end
end
