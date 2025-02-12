require 'faker'

FactoryBot.define do
  factory :user do
    name { "John Doe" }
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    jti { SecureRandom.uuid }

    after(:build) do |user|
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    end
  end
end
