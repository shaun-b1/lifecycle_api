module Api
  module V1
    class UserSerializer < ActiveModel::Serializer
      attributes :id, :name, :email

      has_many :bicycles
    end
  end
end
