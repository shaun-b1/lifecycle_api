class MaintenanceAction < ApplicationRecord
  belongs_to :service

  validates :component_type, presence: true
  validates :action_performed, presence: true

  scope :by_component, ->(type) { where(component_type: type) }

  def action_summary
    "#{component_type.humanize}: #{action_performed}"
  end
end