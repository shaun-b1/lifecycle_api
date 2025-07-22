module Api::V1::KilometreValidatable
  extend ActiveSupport::Concern

  included do
    validates :kilometres, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    before_validation :set_default_kilometres, if: :new_record?
  end

  private

  def set_default_kilometres
    self.kilometres ||= 0
  end
end
