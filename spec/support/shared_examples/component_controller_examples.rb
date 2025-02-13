# spec/support/shared_examples/component_controller_examples.rb
RSpec.shared_examples "a component controller" do |component_type|
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
  let(:other_bicycle) { create(:bicycle, user: other_user) }
  let(:component) { create(component_type, bicycle: bicycle, brand: "Test Brand", kilometres: 0) }
  let(:other_component) { create(component_type, bicycle: other_bicycle, brand: "Test Brand", kilometres: 0) }
  let(:valid_attributes) { { brand: "Test Brand", kilometres: 0, bicycle_id: bicycle.id } }

  context 'when user is authenticated' do
    before do
      token = JWT.encode(
        {
          sub: user.id,
          exp: 24.hours.from_now.to_i,
          jti: user.jti
        },
        Rails.application.credentials.devise_jwt_secret_key,
        'HS256'
      )
      @request.headers['Authorization'] = "Bearer #{token}"
      controller.instance_variable_set(:@current_user_id, user.id)
      controller.instance_variable_set(:@current_user, user)
    end

    describe "GET #show" do
      it "returns success for user's own component" do
        get :show, params: { id: component.id }, format: :json
        expect(response).to have_http_status(:success)
      end

      it "returns forbidden for other user's component" do
        get :show, params: { id: other_component.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST #create" do
      it "creates a component for user's bicycle" do
        expect {
          post :create, params: { component_type => valid_attributes }, format: :json
        }.to change(component_type.to_s.classify.constantize, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it "returns forbidden when creating for other user's bicycle" do
        post :create,
             params: { component_type => valid_attributes.merge(bicycle_id: other_bicycle.id) },
             format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "returns error when creating duplicate component for a bicycle" do
        create(component_type, bicycle: bicycle, brand: "Existing Brand", kilometres: 0)
        post :create, params: { component_type => valid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "PATCH #update" do
      let(:new_attributes) { { brand: "New Brand" } }

      it "updates user's own component" do
        patch :update,
              params: { id: component.id, component_type => new_attributes },
              format: :json
        expect(response).to have_http_status(:success)
        expect(component.reload.brand).to eq("New Brand")
      end

      it "returns forbidden for other user's component" do
        patch :update,
              params: { id: other_component.id, component_type => new_attributes },
              format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "DELETE #destroy" do
      it "deletes user's own component" do
        component # Create the component
        expect {
          delete :destroy, params: { id: component.id }, format: :json
        }.to change(component_type.to_s.classify.constantize, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it "returns forbidden for other user's component" do
        delete :destroy, params: { id: other_component.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
