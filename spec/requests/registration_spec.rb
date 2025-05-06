require 'rails_helper'
require 'factory_bot_rails'

RSpec.describe "Registration", type: :request do
  let(:valid_attributes) {
    {
      user: {
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123",
        name: "Test User"
      }
    }
  }

  describe "POST /api/v1/register" do
    context "with valid parameters" do
      it "creates a new User" do
       expect {
          post "/api/v1/register",
               params: valid_attributes,
               as: :json
        }.to change(User, :count).by(1)
      end

      it "returns a created status" do
        post "/api/v1/register",
             params: valid_attributes,
             as: :json

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["message"]).to eq("Signed up successfully.")
      end

      it "returns the created user data" do
        post "/api/v1/register",
             params: valid_attributes,
             as: :json

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["user"]["email"]).to eq("test@example.com")
        expect(json_response["data"]["user"]["name"]).to eq("Test User")
      end
    end

    context "with invalid parameters" do
      it "does not create a new User without email" do
        invalid_attributes = valid_attributes
        invalid_attributes[:user][:email] = nil

        expect {
          post "/api/v1/register",
               params: invalid_attributes,
               as: :json
        }.not_to change(User, :count)

        expect(json_response[:error]).to eq({
          code: "VALIDATION_ERROR",
          message: "User couldn't be created successfully",
          details: [ "Email can't be blank", "Email is invalid" ],
          status: 422,
          status_text: "Unprocessable Entity"
        })
      end

      it "does not create a new User with invalid email format" do
        invalid_attributes = valid_attributes
        invalid_attributes[:user][:email] = "invalid_email"

        expect {
          post "/api/v1/register",
               params: invalid_attributes,
               as: :json
        }.not_to change(User, :count)

        expect(json_response[:error]).to eq({
          code: "VALIDATION_ERROR",
          message: "User couldn't be created successfully",
          details: [ "Email is invalid" ],
          status: 422,
          status_text: "Unprocessable Entity"
        })
      end

      it "does not create a new User with mismatched passwords" do
        invalid_attributes = valid_attributes
        invalid_attributes[:user][:password_confirmation] = "differentpassword"

        expect {
          post "/api/v1/register",
               params: invalid_attributes,
               as: :json
        }.not_to change(User, :count)

        expect(json_response[:error]).to eq({
          code: "VALIDATION_ERROR",
          message: "User couldn't be created successfully",
          details: [ "Password confirmation doesn't match Password" ],
          status: 422,
          status_text: "Unprocessable Entity"
        })
      end

      it "does not create a new User with too short password" do
        invalid_attributes = valid_attributes
        invalid_attributes[:user][:password] = "short"
        invalid_attributes[:user][:password_confirmation] = "short"

        expect {
          post "/api/v1/register",
               params: invalid_attributes,
               as: :json
        }.not_to change(User, :count)

        expect(json_response[:error]).to eq({
          code: "VALIDATION_ERROR",
          message: "User couldn't be created successfully",
          details: [ "Password is too short (minimum is 6 characters)" ],
          status: 422,
          status_text: "Unprocessable Entity"
        })
      end

      it "does not create a new User without a name" do
        invalid_attributes = valid_attributes
        invalid_attributes[:user][:name] = nil

        expect {
          post "/api/v1/register",
               params: invalid_attributes,
               as: :json
        }.not_to change(User, :count)

        expect(json_response[:error]).to eq({
          code: "VALIDATION_ERROR",
          message: "User couldn't be created successfully",
          details: [ "Name can't be blank" ],
          status: 422,
          status_text: "Unprocessable Entity"
        })
      end

      it "does not create a User with duplicate email" do
        create(:user, email: "test@example.com")

        expect {
          post "/api/v1/register",
               params: valid_attributes,
               as: :json
        }.not_to change(User, :count)

        expect(json_response[:error]).to eq({
          code: "VALIDATION_ERROR",
          message: "User couldn't be created successfully",
          details: [ "Email has already been taken" ],
          status: 422,
          status_text: "Unprocessable Entity"
        })
      end
    end
  end
end
