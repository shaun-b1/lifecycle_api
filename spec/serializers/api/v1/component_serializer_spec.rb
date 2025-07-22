require 'rails_helper'

RSpec.describe Api::V1::ComponentSerializer do
  let(:user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }

  # Test each component type
  describe 'serialization' do
    component_types = {
      chain: Api::V1::Chain,
      cassette: Api::V1::Cassette,
      chainring: Api::V1::Chainring,
      tire: Api::V1::Tire,
      brakepad: Api::V1::Brakepad
    }

    component_types.each do |component_name, component_class|
      context "with a #{component_name}" do
        let(:component) { create(component_name, bicycle: bicycle, brand: "Test Brand", kilometres: 150) }
        let(:serialized_component) { JSON.parse(Api::V1::ComponentSerializer.new(component).to_json) }

        it 'includes all basic attributes' do
          expect(serialized_component).to include('id', 'brand', 'kilometres', 'type')
          expect(serialized_component['brand']).to eq('Test Brand')
          expect(serialized_component['kilometres']).to eq(150)
        end

        it 'returns the correct type' do
          expect(serialized_component['type']).to eq(component_class.name.split('::').last.underscore)
        end
      end
    end
  end
end
