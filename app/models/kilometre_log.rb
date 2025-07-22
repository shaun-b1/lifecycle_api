class KilometreLog < ApplicationRecord
  belongs_to :trackable, polymorphic: true

  validates :event_type,
    presence: true,
    inclusion: { in: %w[increase decrease maintenance reset] }
  validates :previous_value, :new_value, numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { order(created_at: :desc) }
  scope :maintenance, -> { where(event_type: "maintenance") }
  scope :rides, -> { where(event_type: "increase") }

  def change_magnitude
    (new_value - previous_value).abs
  end
end
