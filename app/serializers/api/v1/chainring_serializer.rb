class Api::V1::ChainringSerializer < ActiveModel::Serializer
  include Api::V1::KilometresSerializer
  attributes :id, :brand, :kilometres
end
