module Api::V1::ComponentValidatable
  extend ActiveSupport::Concern

  included do
    validates :brand, presence: true, length: { minimum: 2, maximum: 50 }
    validates :brand, format: {
      with: /\A[a-zA-Z0-9\s\-&'\.]+\z/,
      message: "can only contain letters, numbers, spaces, hyphens, ampersands, apostrophes, and periods"
    }

    validates :model, presence: true, length: { minimum: 1, maximum: 50 }
    validates :model, format: {
      with: /\A[a-zA-Z0-9\s\-&'\.]+\z/,
      message: "can only contain letters, numbers, spaces, hyphens, ampersands, apostrophes, and periods"
    }

    validates :status, inclusion: { in: %w[active replaced] }

    before_validation :normalize_brand_name
    before_validation :normalize_model_name
  end

  private

  def normalize_brand_name
    return unless brand.present?
    self.brand = brand.strip.squeeze(" ").titleize
  end

  def normalize_model_name
    return unless model.present?
    self.model = model.strip.squeeze(" ").titleize
  end
end
