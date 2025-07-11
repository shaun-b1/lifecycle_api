require 'rails_helper'

RSpec.describe 'Components API', type: :request do
  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
  let(:auth_headers) { jwt_auth_headers(user) }

  # Test each component endpoint
  %w[chains cassettes chainrings tires brakepads].each do |component_type|
    singular = component_type.singularize

    describe "GET /api/v1/bicycles/:bicycle_id/#{component_type}/:id" do
      let(:component) { create(singular.to_sym, bicycle: bicycle) }

      it 'returns the component with type information' do
        get "/api/v1/bicycles/#{bicycle.id}/#{component_type}/#{component.id}",
          headers: auth_headers

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]).to include('id', 'brand', 'kilometres', 'type')
        expect(json_response["data"]['type']).to eq(singular)
      end
    end
  end
end
