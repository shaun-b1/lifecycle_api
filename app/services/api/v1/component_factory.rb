class Api::V1::ComponentFactory
  COMPONENT_TYPES = %w[chain cassette chainring tire brakepad].freeze

  def self.create_for(bicycle, component_type, attributes)
    validate_component_type!(component_type)
    
    association_name = "all_#{component_type.to_s.pluralize}"
    bicycle.send(association_name).create(attributes)
  end

  private

  def self.validate_component_type!(component_type)
    unless COMPONENT_TYPES.include?(component_type.to_s)
      raise ArgumentError, "Invalid component type: #{component_type}. Valid types: #{COMPONENT_TYPES.join(', ')}"
    end
  end
end