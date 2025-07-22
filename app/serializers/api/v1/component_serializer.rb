class Api::V1::ComponentSerializer < ActiveModel::Serializer
  include Api::V1::KilometresSerializer

  attributes :id, :brand, :kilometres, :type

  def type
    object.class.name.split('::').last.underscore
  end
end
