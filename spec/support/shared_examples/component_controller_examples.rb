RSpec.shared_examples "a component controller" do |component_type|
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
  let(:other_bicycle) { create(:bicycle, user: other_user) }
  let(:component) { create(component_type, bicycle: bicycle, brand: "Test Brand", kilometres: 0) }
  let(:other_component) { create(component_type, bicycle: other_bicycle, brand: "Test Brand", kilometres: 0) }
  let(:valid_attributes) { { brand: "Test Brand", kilometres: 0 } }

  context 'when user is authenticated' do
    before do
      authenticate_user_in_controller(user)
    end

    describe "GET #show" do
      it "returns success for user's own component" do
        get :show, params: { bicycle_id: bicycle.id, id: component.id }, format: :json
        expect(response).to have_http_status(:success)
      end

      it "returns forbidden for other user's component" do
        get :show, params: { bicycle_id: other_bicycle.id, id: other_component.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST #create" do
      it "creates a component for user's bicycle" do
        expect {
          post :create,
            params: { :bicycle_id => bicycle.id, component_type => valid_attributes },
            format: :json
        }.to change(component_type.to_s.classify.constantize, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it "returns forbidden when creating for other user's bicycle" do
        post :create,
          params: { :bicycle_id => other_bicycle.id, component_type => valid_attributes },
          format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "PATCH #update" do
      let(:new_attributes) { { brand: "New Brand" } }

      it "updates user's own component" do
        patch :update,
          params: { :bicycle_id => bicycle.id, :id => component.id,
                    component_type => new_attributes
},
          format: :json
        expect(response).to have_http_status(:success)
        expect(component.reload.brand).to eq("New Brand")
      end

      it "returns forbidden for other user's component" do
        patch :update,
          params: { :bicycle_id => other_bicycle.id, :id => other_component.id,
                    component_type => new_attributes
},
          format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "DELETE #destroy" do
      it "deletes user's own component" do
        component # Create the component
        expect {
          delete :destroy, params: { bicycle_id: bicycle.id, id: component.id }, format: :json
        }.to change(component_type.to_s.classify.constantize, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it "returns forbidden for other user's component" do
        delete :destroy,
          params: { bicycle_id: other_bicycle.id, id: other_component.id },
          format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
