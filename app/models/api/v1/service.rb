class Api::V1::Service < ApplicationRecord
  belongs_to :bicycle, class_name: 'Api::V1::Bicycle'
  has_many :component_replacements, class_name: 'Api::V1::ComponentReplacement', dependent: :destroy
  has_many :maintenance_actions, class_name: 'Api::V1::MaintenanceAction', dependent: :destroy

  validates :performed_at, presence: true
  validates :notes, presence: true
  validates :service_type, inclusion: {
    in: %w[full_service partial_replacement tune_up emergency_repair inspection],
    message: "must be a valid service type"
  }

  scope :recent, -> { order(performed_at: :desc) }
  scope :by_type, ->(type) { where(service_type: type) }
  scope :this_year, -> { where(performed_at: Date.current.beginning_of_year..Date.current.end_of_year) }

  def components_replaced
    component_replacements.pluck(:component_type).uniq
  end

  def full_service?
    service_type == "full_service"
  end
end
