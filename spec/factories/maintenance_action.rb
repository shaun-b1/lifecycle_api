FactoryBot.define do
  factory :maintenance_action, class: 'Api::V1::MaintenanceAction' do
    association :service
    component_type { "brakes" }
    action_performed { "Cleaned and adjusted" }
    notes { "Standard maintenance" }
  end
end
