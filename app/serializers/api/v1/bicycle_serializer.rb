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
      hash["chain"] = Api::V1::ComponentSerializer.new(object.chain) if object.chain.present?
      hash["cassette"] = Api::V1::ComponentSerializer.new(object.cassette) if object.cassette.present?
      hash["chainring"] = Api::V1::ComponentSerializer.new(object.chainring) if object.chainring.present?
      hash["tires"] = object.tires.map { |tire| Api::V1::ComponentSerializer.new(tire) } if object.tires.present?
      hash["brakepads"] = object.brakepads.map { |brakepad| Api::V1::ComponentSerializer.new(brakepad) } if object.brakepads.present?
    end
    hash
  end
end
