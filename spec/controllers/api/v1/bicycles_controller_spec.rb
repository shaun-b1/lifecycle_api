require 'rails_helper'

RSpec.describe Api::V1::BicyclesController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
  let(:other_bicycle) { create(:bicycle, user: other_user) }

  context 'when user is authenticated' do
    before do
      authenticate_user_in_controller(user)
      controller.instance_variable_set(:@current_user_id, user.id)
      controller.instance_variable_set(:@current_user, user)
    end

    describe "GET #index" do
      it "returns only the user's bicycles" do
        bicycle
        other_bicycle

        get :index, format: :json
        expect(response).to have_http_status(:success)

        response_body = JSON.parse(response.body)
        expect(response_body['success']).to eq(true)

        bicycles = response_body['data']
        expect(bicycles.map { |b| b['id'] }).to include(bicycle.id)
        expect(bicycles.map { |b| b['id'] }).not_to include(other_bicycle.id)
      end
    end

    describe "GET #show" do
      it "returns success for user's own bicycle" do
        get :show, params: { id: bicycle.id }, format: :json
        expect(response).to have_http_status(:success)
      end

      it "returns forbidden for other user's bicycle" do
        get :show, params: { id: other_bicycle.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST #create" do
      let(:valid_attributes) { { name: "New Bike", brand: "Specialized", model: "Allez", kilometres: 0 } }

      it "creates a bicycle and assigns it to current user" do
        post :create, params: { bicycle: valid_attributes }, format: :json
        expect(response).to have_http_status(:created)
        expect(Bicycle.last.user).to eq(user)
      end
    end

    describe "PATCH #update" do
      let(:new_attributes) { { name: "Updated Name" } }

      it "updates user's own bicycle" do
        patch :update, params: { id: bicycle.id, bicycle: new_attributes }, format: :json
        expect(response).to have_http_status(:success)
        expect(bicycle.reload.name).to eq("Updated Name")
      end

      it "returns forbidden for other user's bicycle" do
        patch :update, params: { id: other_bicycle.id, bicycle: new_attributes }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "DELETE #destroy" do
      it "deletes user's own bicycle" do
        delete :destroy, params: { id: bicycle.id }, format: :json
        expect(response).to have_http_status(:ok)
        expect(Bicycle.exists?(bicycle.id)).to be false
      end

      it "returns forbidden for other user's bicycle" do
        delete :destroy, params: { id: other_bicycle.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'when user is not authenticated' do
    it 'returns unauthorized status' do
      get :index, format: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
