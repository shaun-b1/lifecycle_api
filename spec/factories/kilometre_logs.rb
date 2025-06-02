FactoryBot.define do
  factory :kilometre_log do
    trackable { nil }
    event_type { "MyString" }
    previous_value { 1.5 }
    new_value { 1.5 }
    notes { "MyText" }
  end
end
