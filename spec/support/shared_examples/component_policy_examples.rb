RSpec.shared_examples "a component policy" do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:bicycle) { create(:bicycle, user: user) }
  let(:other_bicycle) { create(:bicycle, user: other_user) }
  let(:component) { create(described_class.to_s.underscore.to_sym, bicycle: bicycle) }
  let(:other_component) { create(described_class.to_s.underscore.to_sym, bicycle: other_bicycle) }

  permissions :show?, :update?, :destroy? do
    it "denies access if component belongs to another user's bicycle" do
      expect(subject).not_to permit(user, other_component)
    end

    it "allows access if component belongs to user's bicycle" do
      expect(subject).to permit(user, component)
    end
  end

  permissions :create? do
    it "allows creating component for user's own bicycle" do
      new_component = build(described_class.to_s.underscore.to_sym, bicycle: bicycle)
      expect(subject).to permit(user, new_component)
    end

    it "denies creating component for another user's bicycle" do
      new_component = build(described_class.to_s.underscore.to_sym, bicycle: other_bicycle)
      expect(subject).not_to permit(user, new_component)
    end
  end

  describe "scope" do
    before do
      component
      other_component
    end

    it "shows only components from user's bicycles" do
      scope = Pundit.policy_scope(user, described_class.to_s.constantize)
      expect(scope).to include(component)
      expect(scope).not_to include(other_component)
    end
  end
end
