FactoryBot.define do
  factory :service do
    association :bicycle
    performed_at { Time.current }
    notes { "Standard maintenance service" }
    service_type { "partial_replacement" }
  end
end