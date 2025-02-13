require 'rails_helper'

RSpec.describe Api::V1::CassettesController, type: :controller do
  it_behaves_like "a component controller", :cassette
end
