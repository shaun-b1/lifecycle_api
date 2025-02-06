module Api
  module V1
    class ChainSerializer < ActiveModel::Serializer
      include Api::V1::KilometresSerializer
      attributes :id, :brand, :kilometres
    end
  end
end
