module Api
  module V1
    class ChainSerializer < ActiveModel::Serializer
      include Api::V1::KilometresSerializer
      attributes :id, :brand, :kilometers
    end
  end
end
