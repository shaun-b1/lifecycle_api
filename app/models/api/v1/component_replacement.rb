class Api::V1::ComponentReplacement < ApplicationRecord
  belongs_to :service, class_name: 'Api::V1::Service'

  validates :component_type, presence: true, inclusion: {
    in: %w[chain cassette chainring tire brakepad],
    message: "must be a valid component type"
  }
  validates :reason, presence: true
  validates :new_component_specs, presence: true

  scope :by_component, ->(type) { where(component_type: type) }
  scope :recent, -> { joins(:service).order("services.performed_at DESC") }

  def old_kilometres
    return 0 unless old_component_specs

    if old_component_specs.is_a?(Array)
      old_component_specs.map { |spec| spec["kilometres"] || 0 }.max
    else
      old_component_specs["kilometres"] || 0
    end
  end

  def brand_changed?
    return false unless old_component_specs && new_component_specs

    old_brand = extract_brand(old_component_specs)
    new_brand = extract_brand(new_component_specs)
    old_brand != new_brand
  end

  def replacement_summary
    "#{component_type.humanize}: #{extract_brand(old_component_specs)} → #{extract_brand(new_component_specs)}"
  end

  private

  def extract_brand(specs)
    return "Unknown" unless specs

    if specs.is_a?(Array)
      specs.first&.dig("brand") || "Unknown"
    else
      specs["brand"] || "Unknown"
    end
  end
end
