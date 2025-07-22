FactoryBot.define do
  factory :service, class: 'Api::V1::Service' do
    association :bicycle
    performed_at { Time.current }
    notes { "Standard maintenance service" }
    service_type { "partial_replacement" }

    trait :old_service do
      performed_at { 1.month.ago }
    end

    trait :recent_service do
      performed_at { 1.day.ago }
    end
  end
end
