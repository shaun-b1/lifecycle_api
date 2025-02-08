class Bicycle < ApplicationRecord
  belongs_to :user
  has_one :chain, dependent: :destroy
  has_one :cassette, dependent: :destroy
  has_one :chainring, dependent: :destroy
  has_many :tires, dependent: :destroy
  has_many :brakepads, dependent: :destroy
end
