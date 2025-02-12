FactoryBot.define do
  factory :bicycle do
    association :user
    name { "Bike #{Faker::Number.number(digits: 2)}" }
    brand { %w[Condor Ritchey Cannondale Specialized Trek].sample }
    model { "Model #{Faker::Alphanumeric.alpha(number: 5)}" }
    kilometres { 0.0 }

    # Nested factory for a bicycle with components
    factory :bicycle_with_components do
      after(:create) do |bicycle|
        create(:chain, bicycle: bicycle)
        create(:cassette, bicycle: bicycle)
        create(:chainring, bicycle: bicycle)
        create_list(:tire, 2, bicycle: bicycle)
        create_list(:brakepad, 2, bicycle: bicycle)
      end
    end
  end
end
