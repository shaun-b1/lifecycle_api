class User < ApplicationRecord
  has_many :bicycles, dependent: :destroy
end
