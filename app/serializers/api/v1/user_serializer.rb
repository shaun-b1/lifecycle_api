class Api::V1::UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email

  has_many :bicycles, serializer: Api::V1::BicycleSerializer
end
