require 'rails_helper'

RSpec.describe Api::V1::Bicycle, type: :model do
  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
end
