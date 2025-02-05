class Bicycle < ApplicationRecord
  belongs_to :user
  has_one :chain, dependent: :destroy
end
