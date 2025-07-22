FactoryBot.define do
  factory :chain, class: 'Api::V1::Chain' do
    association :bicycle
    brand { "Campagnolo" }
    model { "Chorus" }
    kilometres { 0.0 }
    status { 'active' }
  end

  factory :cassette, class: 'Api::V1::Cassette' do
    association :bicycle
    brand { "Campagnolo" }
    model { "Chorus" }
    kilometres { 0.0 }
    status { 'active' }
  end

  factory :chainring, class: 'Api::V1::Chainring' do
    association :bicycle
    brand { "Campagnolo" }
    model { "Chorus" }
    kilometres { 0.0 }
    status { 'active' }
  end

  factory :tire, class: 'Api::V1::Tire' do
    association :bicycle
    brand { "Continental" }
    model { "GP5000" }
    kilometres { 0.0 }
    status { 'active' }
  end

  factory :brakepad, class: 'Api::V1::Brakepad' do
    association :bicycle
    brand { "Campagnolo" }
    model { "Chorus" }
    kilometres { 0.0 }
    status { 'active' }
  end
end
