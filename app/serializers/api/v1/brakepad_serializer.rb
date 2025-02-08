class Api::V1::BrakepadSerializer < ActiveModel::Serializer
  include Api::V1::KilometresSerializer
  attributes :id, :brand, :kilometres
end
