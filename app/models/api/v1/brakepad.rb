class Api::V1::Brakepad < ApplicationRecord
  include Api::V1::BicycleComponent
  max_components_per_bicycle 2
end
