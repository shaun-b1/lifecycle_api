require_dependency "bicycle_component"

class Chain < ApplicationRecord
  include BicycleComponent
end
