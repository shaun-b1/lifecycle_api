FactoryBot.define do
  factory :component_replacement do
    association :service
    component_type { "chain" }
    old_component_specs { { brand: "Old Brand", kilometres: 1500 } }
    new_component_specs { { brand: "New Brand", model: "New Model" } }
    reason { "Wear limit exceeded" }
  end
end