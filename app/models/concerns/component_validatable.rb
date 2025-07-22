module ComponentValidatable
  extend ActiveSupport::Concern

  included do
    validates :brand, presence: true, length: { minimum: 2, maximum: 50 }
    validates :brand, format: {
      with: /\A[a-zA-Z0-9\s\-&'\.]+\z/,
      message: "can only contain letters, numbers, spaces, hyphens, ampersands, apostrophes, and periods"
    }

    before_validation :normalize_brand_name
  end

  private

  def normalize_brand_name
    return unless brand.present?

    self.brand = brand.strip.squeeze(" ").titleize
  end
end
