class Api::V1::ChainSerializer < ActiveModel::Serializer
  include Api::V1::KilometresSerializer
  attributes :id, :brand, :kilometres
end
