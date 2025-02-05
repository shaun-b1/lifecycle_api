module Api
  module V1
    class BicycleSerializer < ActiveModel::Serializer
      include Api::V1::KilometresSerializer
      attributes :id, :name, :brand, :model, :kilometres

      has_many :chains, serializer: Api::V1::ChainSerializer
    end
  end
end
