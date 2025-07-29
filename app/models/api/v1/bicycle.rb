class Api::V1::Bicycle < ApplicationRecord
  include Api::V1::KilometreValidatable
  include Api::V1::KilometreTrackable

  belongs_to :user

  has_one :chain, -> { where(status: "active") }, class_name: 'Api::V1::Chain', dependent: :destroy
  has_one :cassette, -> { where(status: "active") }, class_name: 'Api::V1::Cassette', dependent: :destroy
  has_one :chainring, -> { where(status: "active") }, class_name: 'Api::V1::Chainring', dependent: :destroy
  has_many :tires, -> { where(status: "active") }, class_name: 'Api::V1::Tire', dependent: :destroy
  has_many :brakepads, -> { where(status: "active") }, class_name: 'Api::V1::Brakepad', dependent: :destroy

  has_many :all_chains, class_name: "Api::V1::Chain", dependent: :destroy
  has_many :all_cassettes, class_name: "Api::V1::Cassette", dependent: :destroy
  has_many :all_chainrings, class_name: "Api::V1::Chainring", dependent: :destroy
  has_many :all_tires, class_name: "Api::V1::Tire", dependent: :destroy
  has_many :all_brakepads, class_name: "Api::V1::Brakepad", dependent: :destroy

  validates :name, presence: true
  validates :brand, presence: true
  validates :model, presence: true
  validates :terrain, inclusion: { in: %w[flat hilly mountainous], allow_nil: true }
  validates :weather, inclusion: { in: %w[dry mixed wet], allow_nil: true }
  validates :particulate, inclusion: { in: %w[low medium high], allow_nil: true }

  has_many :services, class_name: 'Api::V1::Service', dependent: :destroy
  has_many :component_replacements, class_name: 'Api::V1::ComponentReplacement', through: :services
  has_many :maintenance_actions, class_name: 'Api::V1::MaintenanceAction', through: :services

  def last_service
    services.recent.first
  end

  def services_this_year
    services.this_year
  end

  def component_replacement_history(component_type)
    component_replacements.by_component(component_type).recent
  end

  def last_component_replacement(component_type)
    component_replacement_history(component_type).first
  end

  def create_component(component_type, attributes)
    Api::V1::ComponentFactory.create_for(self, component_type, attributes)
  end

  def adjusted_wear_limits
    wear_calculator.adjusted_wear_limits
  end

  def riding_environment
    @riding_environment ||= Api::V1::RidingEnvironment.new(
      terrain: terrain,
      weather: weather,
      particulate: particulate
    )
  end

  def maintenance_recommendations
    Api::V1::MaintenanceRecommendationService.new(self, adjusted_wear_limits).recommendations
  end

  def component_status
    Api::V1::ComponentStatusGenerator.new(self, adjusted_wear_limits, riding_environment).status
  end

  private

  def wear_calculator
    @wear_calculator ||= Api::V1::BicycleWearCalculator.new(riding_environment)
  end
end
