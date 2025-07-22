class Api::V1::Tire < ApplicationRecord
  include Api::V1::BicycleComponent
  max_components_per_bicycle 2
end
