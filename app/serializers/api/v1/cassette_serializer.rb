class Api::V1::CassetteSerializer < ActiveModel::Serializer
  include Api::V1::KilometresSerializer
  attributes :id, :brand, :kilometres
end
