class Api::V1::ComponentsController < ApplicationController
  before_action :set_bicycle
  before_action :set_component, only: %i[show update destroy]

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
      render json: @component.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @component
    if @component.update(component_params)
      render json: @component, serializer: component_serializer
    else
      render json: @component.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @component
    @component.destroy
    head :no_content
  end

  private

  def set_bicycle
    @bicycle = Bicycle.find(params[:bicycle_id])
  end

  def component_class
    raise NotImplementedError, "Subclasses must define component_class"
  end

  def component_serializer
    raise NotImplementedError, "Subclasses must define component_serializer"
  end

  def component_param_key
    component_class.to_s.underscore
  end

  def set_component
    @component = find_component
  end

  def find_component
    # For components with a has_one association (chains, cassettes, chainrings)
    if @bicycle.respond_to?(component_class.to_s.underscore)
      @bicycle.send(component_class.to_s.underscore)
    # For components with a has_many association (tires, brakepads)
    else
      @bicycle.send(component_class.to_s.pluralize.underscore).find(params[:id])
    end
  end

  def build_component(attributes)
    # For components with a has_one association (chains, cassettes, chainrings)
    if @bicycle.respond_to?("build_#{component_class.to_s.underscore}")
      @bicycle.send("build_#{component_class.to_s.underscore}", attributes)
    # For components with a has_many association (tires, brakepads)
    else
      @bicycle.send(component_class.to_s.pluralize.underscore).build(attributes)
    end
  end

  def component_params
    params.require(component_param_key).permit(:brand, :kilometres)
  end
end
