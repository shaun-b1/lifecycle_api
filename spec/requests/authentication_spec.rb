require 'rails_helper'
require 'factory_bot_rails'

RSpec.describe "Authentication", type: :request do
  let!(:user) { create(:user) }
  let!(:bicycle) { create(:bicycle, user: user) }

  describe "Session management" do
    it "can sign in a user and access protected resources" do
      login_params = {
        user: {
          email: user.email,
          password: user.password
        }
      }

      post "/api/v1/login",
           params: login_params,
           as: :json

      expect(response).to have_http_status(:ok)
      token = response.headers['Authorization']&.split(' ')&.last

      expect(token).to be_present

      get "/api/v1/bicycles/#{bicycle.id}",
          headers: {
            "Authorization" => "Bearer #{token}",
            "Accept" => "application/json"
          }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["name"]).to eq(bicycle.name)
    end

    context "with invalid credentials" do
      it "returns unauthorized for incorrect password" do
        post "/api/v1/login",
             params: {
               user: {
                 email: user.email,
                 password: "wrongpassword"
               }
             },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to have_key("error")
      end

      it "returns unauthorized for non-existent user" do
        post "/api/v1/login",
             params: {
               user: {
                 email: "nonexistent@example.com",
                 password: "password123"
               }
             },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to have_key("error")
      end
    end

    context "with invalid or missing token" do
      it "returns unauthorized for request without token" do
        get "/api/v1/bicycles/#{bicycle.id}",
            headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to have_key("error")
      end

      it "returns unauthorized for request with invalid token" do
        get "/api/v1/bicycles/#{bicycle.id}",
            headers: {
              "Authorization" => "Bearer invalid_token",
              "Accept" => "application/json"
            }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to have_key("error")
      end
    end

    context "with logout" do
      it "successfully logs out and invalidates the token" do
        # First login to get a token
        post "/api/v1/login",
             params: {
               user: {
                 email: user.email,
                 password: user.password
               }
             },
             as: :json

        token = response.headers['Authorization']&.split(' ')&.last
        expect(token).to be_present

        # Logout
        delete "/api/v1/logout",
               headers: {
                 "Authorization" => "Bearer #{token}",
                 "Accept" => "application/json"
               }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["message"]).to eq("Logged out successfully.")

        # Try to use the token after logout
        get "/api/v1/bicycles/#{bicycle.id}",
            headers: {
              "Authorization" => "Bearer #{token}",
              "Accept" => "application/json"
            }

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns unauthorized when trying to logout without a token" do
        delete "/api/v1/logout",
               headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
