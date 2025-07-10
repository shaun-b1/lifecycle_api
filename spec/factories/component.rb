FactoryBot.define do
  factory :chain do
    association :bicycle
    brand { "Campagnolo" }
    model { "Chorus" }
    kilometres { 0.0 }
    status { 'active' }
  end

  factory :cassette do
    association :bicycle
    brand { "Campagnolo" }
    model { "Chorus" }
    kilometres { 0.0 }
    status { 'active' }
  end

  factory :chainring do
    association :bicycle
    brand { "Campagnolo" }
    model { "Chorus" }
    kilometres { 0.0 }
    status { 'active' }
  end

  factory :tire do
    association :bicycle
    brand { "Continental" }
    model { "GP5000" }
    kilometres { 0.0 }
    status { 'active' }
  end

  factory :brakepad do
    association :bicycle
    brand { "Campagnolo" }
    model { "Chorus" }
    kilometres { 0.0 }
    status { 'active' }
  end
end
