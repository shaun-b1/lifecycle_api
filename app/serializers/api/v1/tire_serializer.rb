class Api::V1::TireSerializer < ActiveModel::Serializer
  include Api::V1::KilometresSerializer
  attributes :id, :brand, :kilometres
end
