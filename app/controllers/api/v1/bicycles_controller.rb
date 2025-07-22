class Api::V1::BicyclesController < ApplicationController
  include Api::V1::CrudOperations

  def record_ride
    @bicycle = find_resource
    authorize @bicycle

    distance = params[:distance].to_f
    notes = params[:notes]

    begin
      Api::V1::RideRecordingService.record(@bicycle, distance, notes)

      response = Api::V1::ResponseService.success(
        ActiveModelSerializers::SerializableResource.new(
          @bicycle.reload,
          serializer: resource_serializer
        ).as_json,
        "Ride recorded successfully"
      )

      render response
    rescue Api::V1::Errors::ApiError => e
      render json: e.to_hash, status: e.status
    end
  end

  def record_maintenance
    @bicycle = find_resource
    authorize @bicycle

    begin
      service = Api::V1::MaintenanceService.record_maintenance(@bicycle, build_maintenance_options)

      response = Api::V1::ResponseService.success(
        ActiveModelSerializers::SerializableResource.new(
          service,
          include: [ :component_replacements, :maintenance_actions ]
        ).as_json,
        "Maintenance recorded successfully"
      )

      render response
    rescue Api::V1::Errors::ApiError => e
      render json: e.to_hash, status: e.status
    end
  end

  private

  def resource_class
    Api::V1::Bicycle
  end

  def resource_serializer
    ::Api::V1::BicycleSerializer
  end

  def resource_params
    params.require(:bicycle).permit(:name,
      :brand,
      :model,
      :kilometres,
      :terrain,
      :weather,
      :particulate)
  end

  def find_resource
    resource_class.includes(:chain, :cassette, :chainring, :tires, :brakepads).find(params[:id])
  end

  def build_resource(attributes)
    resource = super
    resource.user = current_user
    resource
  end

  def build_maintenance_options
    options = {}

    options[:notes] = params[:notes] if params[:notes].present?

    if params[:full_service] == true || params[:full_service] == "true"
      options[:full_service] = true
      options[:default_brand] = params[:default_brand]
      options[:default_model] = params[:default_model]
      options[:exceptions] = format_exceptions(params[:exceptions]) if params[:exceptions]
    end

    if params[:replacements].present?
      options[:replacements] = format_replacements(params[:replacements])
    end

    if params[:maintenance_actions].present?
      options[:maintenance_actions] = format_maintenance_actions(params[:maintenance_actions])
    end

    if params[:maintenance_actions].present?
      options[:maintenance_actions] = params[:maintenance_actions]
    end

    options
  end

  def format_exceptions(exceptions_params)
    formatted = {}

    exceptions_params.each do |component_type, specs|
      case component_type.to_s
      when "tires", "brakepads"
        formatted[component_type.to_sym] = Array(specs).map do |spec|
          { brand: spec[:brand], model: spec[:model] }
        end
      else
        formatted[component_type.to_sym] = { brand: specs[:brand], model: specs[:model] }
      end
    end

    formatted
  end

  def format_replacements(replacement_params)
    formatted = {}

    replacement_params.each do |component_type, specs|
      case component_type.to_s
      when "tires", "brakepads"
        formatted[component_type.to_sym] = Array(specs).map do |spec|
          { brand: spec[:brand], model: spec[:model] }
        end
      else
        formatted[component_type.to_sym] = { brand: specs[:brand], model: specs[:model] }
      end
    end

    formatted
  end

  def format_maintenance_actions(maintenance_actions_params)
    Array(maintenance_actions_params).map do |action|
      {
        component_type: action[:component_type],
        action_performed: action[:action_performed]
      }
    end
  end
end
