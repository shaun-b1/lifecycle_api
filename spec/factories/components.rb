FactoryBot.define do
  factory :chain do
    association :bicycle
    brand { "Campagnolo" }
    kilometres { 0.0 }
  end

  factory :cassette do
    association :bicycle
    brand { "Campagnolo" }
    kilometres { 0.0 }
  end

  factory :chainring do
    association :bicycle
    brand { "Campagnolo" }
    kilometres { 0.0 }
  end

  factory :tire do
    association :bicycle
    brand { "Continental" }
    kilometres { 0.0 }
  end

  factory :brakepad do
    association :bicycle
    brand { "Campagnolo" }
    kilometres { 0.0 }
  end
end
