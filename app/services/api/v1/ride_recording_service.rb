class Api::V1::RideRecordingService
  def self.record(bicycle, distance, notes = nil)
    if distance <= 0
      raise Api::V1::Errors::ValidationError.new(
        "Ride distance must be greater than zero",
        [ "The distance value must be a positive number" ]
      )
    end

    unless bicycle.present?
      raise Api::V1::Errors::ResourceNotFoundError.new("Bicycle")
    end

    ActiveRecord::Base.transaction do
      bicycle_updated = bicycle.add_kilometres(distance, notes)

      unless bicycle_updated
        raise Api::V1::Errors::ValidationError.new(
          "Failed to update bicycle kilometres",
          bicycle.errors.full_messages
        )
      end

      active_components = [
        bicycle.chain,
        bicycle.chainring,
        bicycle.cassette,
        *bicycle.tires,
        *bicycle.brakepads
      ].compact

      active_components.each do |component|
        component_updated = component.add_kilometres(distance, "Component distance updated from bicycle ride")

        unless component_updated
          raise Api::V1::Errors::ValidationError.new(
            "Failed to update #{component.class.name.downcase} kilometres",
            component.errors.full_messages
          )
        end
      end
    end

    true

  rescue Api::V1::Errors::ApiError => e
    raise e
  rescue => e
    Rails.logger.error("Failed to record ride: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    raise Api::V1::Errors::ApiError.new(
      "An unexpected error occurred while recording the ride",
      "RIDE_RECORDING_ERROR",
      :internal_server_error
    )
  end
end
