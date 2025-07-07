module BicycleComponent
  extend ActiveSupport::Concern

  included do
    include KilometreValidatable
    include KilometreTrackable
    include ComponentValidatable

    belongs_to :bicycle
    validates :bicycle, presence: true
    validate :validate_component_limit
  end

  class_methods do
    def max_components_per_bicycle(count)
      @max_components = count
    end

    def max_components
      @max_components || 1
    end
  end

  def replace_component(new_brand, reset_kilometres = true)
    self.brand = new_brand
    self.kilometres = 0 if reset_kilometres
    save
  end

  private

  def validate_component_limit
    return unless bicycle

    existing = self.class.where(bicycle: bicycle)
    existing = existing.where.not(id: id) if persisted?

    if existing.count >= self.class.max_components
      component_name = self.class.name.underscore.humanize.downcase
      count_description = existing.count == 1 ? "a" : self.class.max_components
      plural_suffix = existing.count == 1 ? "" : "s"

      errors.add(:bicycle_id, "already has #{count_description} #{component_name}#{plural_suffix}")
    end
  end
end
