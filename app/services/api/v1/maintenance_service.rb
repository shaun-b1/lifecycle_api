class MaintenanceService
  def self.record_maintenance(bicycle, options = {})
   unless bicycle.present?
     raise Api::V1::Errors::ResourceNotFoundError.new("Bicycle")
   end

   notes = options[:notes]
   full_service = options[:full_service]
   default_brand = options[:default_brand]
   default_model = options[:default_model]
   exceptions = options[:exceptions] || {}

   ActiveRecord::Base.transaction do
     bicycle_updated = bicycle.record_maintenance(notes || "Maintenance performed")

     unless bicycle_updated
       raise Api::V1::Errors::ValidationError.new(
        "Failed to record bicycle maintenance",
        bicycle.errors.full_messages
       )
     end

     if full_service
       validate_full_service_params(default_brand, default_model)
       replace_all_components(bicycle, default_brand, default_model, exceptions)
     elsif options[:replacements]
      replace_specific_components(bicycle, options[:replacements])
     end
   end

   true
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

  def self.replace_all_components(bicycle, default_brand, default_model, exceptions)
    component_types = %w[chain cassette chainring tires brakepads]

    component_types.each do |component_type|
      if exceptions[component_type.to_sym]
        replace_component_type(bicycle, component_type, exceptions[component_type.to_sym])
      else
        specs = { brand: default_brand, model: default_model }
        replace_component_type(bicycle, component_type, specs)
      end
    end
  end

  def self.replace_specific_components(bicycle, replacements)
    replacements.each do |component_type, specs|
      replace_component_type(bicycle, component_type.to_sym, specs)
    end
  end

  def self.replace_component_type(bicycle, component_type, specs)
    case component_type
    when "chain", "cassette", "chainring"
      replace_single_component(bicycle, component_type, specs)
    when "tires", "brakepads"
      replace_multiple_components(bicycle, component_type, specs)
    end
  end

  def self.replace_single_component(bicycle, component_type, specs)
    old_component = bicycle.send(component_type)
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

  def self.replace_multiple_components(bicycle, component_type, specs_array)
    old_components = bicycle.send(component_type)
    old_components.each do |component|
      unless old_component.update(status: "replaced", replaced_at: Time.current)
        raise Api::V1::Errors::ValidationError.new(
          "Failed to retire old #{component_type.singularize}",
          old_component.errors.full_messages
        )
      end
    end

    Array(specs_array).each do |specs|
      new_component = bicycle.send(component_type).create(specs.merge(kilometres: 0, status: "active"))
      unless new_component.persisted?
        raise Api::V1::Errors::ValidationError.new(
          "Failed to create new #{component_type}",
          new_component.errors.full_messages
        )
      end
    end
  end
end
