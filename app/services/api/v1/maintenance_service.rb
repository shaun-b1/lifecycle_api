class Api::V1::MaintenanceService
  def self.record_maintenance(bicycle, options = {})
    unless bicycle.present?
      raise Api::V1::Errors::ResourceNotFoundError.new("Bicycle")
    end

    notes = options[:notes] || "Maintenance performed"
    full_service = options[:full_service]
    default_brand = options[:default_brand]
    default_model = options[:default_model]
    exceptions = options[:exceptions] || {}

    ActiveRecord::Base.transaction do
      service = Api::V1::Service.create!(
        bicycle: bicycle,
        performed_at: Time.current,
        service_type: full_service ? "full_service" : "partial_replacement",
        notes: notes
      )

      bicycle_updated = bicycle.reset_kilometres(notes)
      unless bicycle_updated
        raise Api::V1::Errors::ValidationError.new(
          "Failed to record bicycle maintenance",
          bicycle.errors.full_messages
        )
      end

      if full_service
        validate_full_service_params(default_brand, default_model)
        replace_all_components(bicycle, service, default_brand, default_model, exceptions)
      elsif options[:replacements]
        replace_specific_components(bicycle, service, options[:replacements])
      end

      create_maintenance_actions(service, options[:maintenance_actions])

      service
    end
  rescue Api::V1::Errors::ApiError => e
    raise e
  rescue => e
    Rails.logger.error("Failed to record maintenance: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    raise Api::V1::Errors::ApiError.new(
      "An unexpected error occurred during maintenance",
      "MAINTENANCE_ERROR",
      :internal_server_error
    )
  end

  private

  def self.validate_full_service_params(default_brand, default_model)
    if default_brand.blank?
      raise Api::V1::Errors::ValidationError.new(
        "Default brand is required for full service",
        [ "default_brand can't be blank" ]
      )
    end

    if default_model.blank?
      raise Api::V1::Errors::ValidationError.new(
        "Default model is required for full service",
        [ "default_model can't be blank" ]
      )
    end
  end

  def self.replace_all_components(bicycle, service, default_brand, default_model, exceptions)
    component_types = %w[chain cassette chainring tires brakepads]

    component_types.each do |component_type|
      if exceptions[component_type.to_sym]
        replace_component_type(bicycle, service, component_type, exceptions[component_type.to_sym])
      else
        case component_type
        when "chain", "cassette", "chainring"
          specs = { brand: default_brand, model: default_model }
          replace_component_type(bicycle, service, component_type, specs)
        when "tires", "brakepads"
          old_components = bicycle.send(component_type)
          specs_array = old_components.map { { brand: default_brand, model: default_model } }
          replace_component_type(bicycle, service, component_type, specs_array)
        end
      end
    end
  end

  def self.replace_specific_components(bicycle, service, replacements)
    replacements.each do |component_type, specs|
      replace_component_type(bicycle, service, component_type.to_s, specs)
    end
  end

  def self.replace_component_type(bicycle, service, component_type, specs)
    case component_type
    when "chain", "cassette", "chainring"
      replace_single_component(bicycle, service, component_type, specs)
    when "tires", "brakepads"
      replace_multiple_components(bicycle, service, component_type, specs)
    end
  end

  def self.replace_single_component(bicycle, service, component_type, specs)
    old_component = bicycle.send(component_type)

    Api::V1::ComponentReplacement.create!(
      service: service,
      component_type: component_type,
      old_component_specs: old_component ? {
        brand: old_component.brand,
        model: old_component.model,
        kilometres: old_component.kilometres,
        status: old_component.status
      } : nil,
      new_component_specs: specs.merge(status: "active"),
      reason: "Component replacement during #{service.service_type}"
    )

    if old_component
      unless old_component.update(status: "replaced", replaced_at: Time.current)
        raise Api::V1::Errors::ValidationError.new(
          "Failed to retire old #{component_type}",
          old_component.errors.full_messages
        )
      end
    end

    new_component = bicycle.send("create_#{component_type}", specs.merge(kilometres: 0, status: "active"))
    unless new_component.persisted?
      raise Api::V1::Errors::ValidationError.new(
        "Failed to create new #{component_type}",
        new_component.errors.full_messages
      )
    end
  end

  def self.replace_multiple_components(bicycle, service, component_type, specs_array)
    old_components = bicycle.send(component_type)

    Api::V1::ComponentReplacement.create!(
      service: service,
      component_type: component_type.singularize, # "tire" not "tires"
      old_component_specs: old_components.map do |component|
        {
          brand: component.brand,
          model: component.model,
          kilometres: component.kilometres,
          status: component.status
        }
      end,
      new_component_specs: Array(specs_array).map { |specs| specs.merge(status: "active") },
      reason: "Component replacement during #{service.service_type}"
    )

    old_components.each do |component|
      unless component.update(status: "replaced", replaced_at: Time.current)
        raise Api::V1::Errors::ValidationError.new(
          "Failed to retire old #{component_type.singularize}",
          component.errors.full_messages
        )
      end
    end

    Array(specs_array).each do |specs|
      singular_type = component_type.singularize
      new_component = bicycle.send("create_#{singular_type}", specs.merge(kilometres: 0, status: "active"))
      unless new_component.persisted?
        raise Api::V1::Errors::ValidationError.new(
          "Failed to create new #{component_type}",
          new_component.errors.full_messages
        )
      end
    end
  end

  def self.create_maintenance_actions(service, maintenance_actions)
    return if maintenance_actions.blank?

    maintenance_actions.each do |action|
      Api::V1::MaintenanceAction.create!(
        service: service,
        component_type: action[:component_type],
        action_performed: action[:action_performed]
      )
    end
  end
end
