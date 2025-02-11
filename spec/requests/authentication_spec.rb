# require 'rails_helper'

# RSpec.describe "Authentication", type: :request do
#   describe "GET /api/v1/bicycles/:id" do
#     let!(:bicycle) { create(:bicycle) } # Assuming you have a factory for bicycles

#     it "returns 401 when no token is provided" do
#       get "/api/v1/bicycles/#{bicycle.id}", headers: { "ACCEPT" => "application/json" }
#       expect(response).to have_http_status(:unauthorized)
#       expect(JSON.parse(response.body)["error"]).to eq("Unauthorized")
#     end
#   end
# end

require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  let!(:user) { create(:user) }  # Assuming you have a factory for users
  let!(:bicycle) { create(:bicycle, user: user) }
  let!(:token) { user.generate_jwt } # Assuming `generate_jwt` is a method in your User model

  describe "GET /api/v1/bicycles/:id" do
    it "returns 200 when a valid token is provided" do
      get "/api/v1/bicycles/#{bicycle.id}",
          headers: { "Authorization" => "Bearer #{token}", "ACCEPT" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["name"]).to eq(bicycle.name)
    end
  end
end
