FactoryBot.define do
  factory :maintenance_action do
    association :service
    component_type { "brakes" }
    action_performed { "Cleaned and adjusted" }
    notes { "Standard maintenance" }
  end
end
