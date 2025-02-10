module Api::V1::KilometresSerializer
  extend ActiveSupport::Concern

  def kilometres
    object.kilometres || 0.0
  end
end
