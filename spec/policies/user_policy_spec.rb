require 'rails_helper'

RSpec.describe UserPolicy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  permissions :show?, :update?, :destroy? do
    it "denies access if user is not viewing their own profile" do
      expect(subject).not_to permit(user, other_user)
    end

    it "allows access if user is viewing their own profile" do
      expect(subject).to permit(user, user)
    end
  end

  describe "scope" do
    it "only shows the user's own profile" do
      user
      other_user
      scope = Pundit.policy_scope(user, User)
      expect(scope).to include(user)
      expect(scope).not_to include(other_user)
    end
  end
end
