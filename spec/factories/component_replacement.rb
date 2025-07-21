FactoryBot.define do
  factory :component_replacement do
    association :service
    component_type { "chain" }
    old_component_specs { { brand: "Old Brand", model: "Old Model", kilometres: 1500 } }
    new_component_specs { { brand: "New Brand", model: "New Model" } }
    reason { "Wear limit exceeded" }

    trait :chain_replacement do
      component_type { "chain" }
    end

    trait :tire_replacement do
      component_type { "tire" }
    end

    trait :with_array_old_specs do
      old_component_specs { [
        { brand: "Front Brand", model: "Front Model", kilometres: 1000 },
        { brand: "Rear Brand", model: "Rear Model", kilometres: 1500 }
      ] }
    end

    trait :different_brands do
      old_component_specs { { brand: "Shimano", model: "Old Model" } }
      new_component_specs { { brand: "SRAM", model: "New Model" } }
    end

    trait :same_brands do
      old_component_specs { { brand: "Shimano", model: "Old Model" } }
      new_component_specs { { brand: "Shimano", model: "New Model" } }
    end

    trait :for_cassette_summary do
      component_type { "cassette" }
      old_component_specs { nil }
      new_component_specs { { brand: "Campagnolo", model: "New Model" } }
    end
  end
end