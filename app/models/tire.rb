class Tire < ApplicationRecord
  include BicycleComponent
  max_components_per_bicycle 2
end
