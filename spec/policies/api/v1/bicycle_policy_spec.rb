require 'rails_helper'

RSpec.describe Api::V1::BicyclePolicy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
  let(:other_bicycle) { create(:bicycle, user: other_user) }

  permissions :show?, :update?, :destroy? do
    it "denies access if bicycle doesn't belong to user" do
      expect(subject).not_to permit(user, other_bicycle)
    end

    it "grants access if bicycle belongs to user" do
      expect(subject).to permit(user, bicycle)
    end
  end

  permissions :create? do
    it "grants access to any authenticated user" do
      expect(subject).to permit(user, Api::V1::Bicycle.new)
    end
  end

  describe "scope" do
    before do
      bicycle            # Create user's bicycle
      other_bicycle     # Create other user's bicycle
    end

    it "shows only user's bicycles" do
      scope = Pundit.policy_scope(user, Api::V1::Bicycle)
      expect(scope).to include(bicycle)
      expect(scope).not_to include(other_bicycle)
    end
  end
end
