class Api::V1::BicycleSerializer < ActiveModel::Serializer
  include Api::V1::KilometresSerializer
  attributes :id, :name, :brand, :model, :kilometres, :riding_environment, :adjusted_wear_limits

  def riding_environment
    object.riding_environment
  end

  def adjusted_wear_limits
    object.adjusted_wear_limits
  end

  has_one :chain
  has_one :cassette
  has_one :chainring
  has_many :tires
  has_many :brakepads

  def initialize(object, options = {})
    super
    @show_components = options[:scope] == :dashboard
  end

  def attributes(*args)
    hash = super
    if @show_components
      hash["chain"] = serialize_component(object.chain)
      hash["cassette"] = serialize_component(object.cassette)
      hash["chainring"] = serialize_component(object.chainring)
      hash["tires"] = serialize_components(object.tires)
      hash["brakepads"] = serialize_components(object.brakepads)
    end
    hash
  end

  private

  def serialize_component(component)
    Api::V1::ComponentSerializer.new(component) if component.present?
  end

  def serialize_components(components)
    components.map { |component| Api::V1::ComponentSerializer.new(component) } if components.present?
  end
end
