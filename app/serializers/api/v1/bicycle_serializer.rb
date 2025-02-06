module Api
  module V1
    class BicycleSerializer < ActiveModel::Serializer
      include Api::V1::KilometresSerializer
      attributes :id, :name, :brand, :model, :kilometres

      has_one :chain


      def initialize(object, options = {})
        super
        @show_chain = options[:scope] == :dashboard
      end

      def attributes(*args)
        hash = super
        hash["chain"] = Api::V1::ChainSerializer.new(object.chain) if @show_chain && object.chain.present?
        hash
      end
    end
  end
end
