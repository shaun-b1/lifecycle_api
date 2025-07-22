class Api::V1::MaintenanceAction < ApplicationRecord
  belongs_to :service, class_name: 'Api::V1::Service'

  validates :component_type, presence: true
  validates :action_performed, presence: true

  scope :by_component, ->(type) { where(component_type: type) }

  def action_summary
    "#{component_type.humanize}: #{action_performed}"
  end
end
