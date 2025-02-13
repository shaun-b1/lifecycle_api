require 'rails_helper'

RSpec.describe Api::V1::BrakepadsController, type: :controller do
  it_behaves_like "a dual component controller", :brakepad
end
