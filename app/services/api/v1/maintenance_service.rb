class Api::V1::MaintenanceService
  def self.record_component_maintenance(component, notes = nil)
    unless component.present?
      raise Api::V1::Errors::ResourceNotFoundError.new("Component")
    end

    success = component.record_maintenance(notes)

    unless success
      raise Api::V1::Errors::ValidationError.new(
        "Failed to record component maintenance",
        component.errors.full_messages
      )
    end

    true
  end

  def self.record_bicycle_maintenance(bicycle, components = [], notes = nil)
    unless bicycle.present?
      raise Api::V1::Errors::ResourceNotFoundError.new("Bicycle")
    end

    ActiveRecord::Base.transaction do
      bicycle_updated = bicycle.record_maintenance("Full bicycle maintenance: #{notes}")

      unless bicycle_updated
        raise Api::V1::Errors::ValidationError.new(
          "Failed to record bicycle maintenance",
          bicycle.errors.full_messages
        )
      end

      components = components.compact.uniq
      components.each do |component|
        next unless bicycle.send(component)

        component_obj = bicycle.send(component)
        if component_obj.is_a?(ActiveRecord::Associations::CollectionProxy)
          component_obj.each do |individual_component|
            success = individual_component.record_maintenance("Maintenance as part of a bicycle service")
            unless success
              raise Api::V1::Errors::ValidationError.new(
                "Failed to record #{individual_component.class.name.downcase} maintenance",
                individual_component.errors.full_messages
              )
            end
          end
        else
          success = component_obj.record_maintenance("Maintenance as part of a bicycle service")
          unless success
            raise Api::V1::Errors::ValidationError.new(
              "Failed to record #{component_obj.class.name.downcase} maintenance",
              component_obj.errors.full_messages
            )
          end
        end
      end
    end

    true
  rescue Api::V1::Errors::ApiError => e
    raise e
  rescue => e
    Rails.logger.error("Failed to record bicycle maintenance: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    raise Api::V1::Errors::ApiError.new(
      "An unexpected error occurred during maintenance recording",
      "MAINTENANCE_RECORDING_ERROR",
      :internal_server_error
    )
  end

  def self.record_full_service(bicycle, notes = nil)
    all_components = [ :chain, :cassette, :chainring, :tires, :brakepads ]
    record_bicycle_maintenance(bicycle, all_components, notes || "Full service")
  end
end
