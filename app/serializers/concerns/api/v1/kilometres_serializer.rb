module Api
  module V1
    module KilometresSerializer
      extend ActiveSupport::Concern

      def kilometres
        object.kilometres || 0.0
      end
    end
  end
end
