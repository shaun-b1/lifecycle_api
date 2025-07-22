RSpec.shared_examples "a bicycle component" do
  describe "validations" do
    let(:user) { create(:user) }
    let(:bicycle) { create(:bicycle, user: user) }
    let(:component) { build(described_class.to_s.split('::').last.underscore.to_sym, bicycle: bicycle) }

    it "is valid with valid attributes" do
      expect(component).to be_valid
    end

    it "is not valid without a bicycle" do
      component.bicycle = nil
      expect(component).not_to be_valid
    end

    it "allows only one component per bicycle" do
      # Create first component
      create(described_class.to_s.split('::').last.underscore.to_sym, bicycle: bicycle)

      # Try to create second component for same bicycle
      duplicate_component = build(described_class.to_s.split('::').last.underscore.to_sym, bicycle: bicycle)

      component_name = described_class.to_s.split('::').last.underscore.humanize.downcase
      expect(duplicate_component).not_to be_valid
      expect(duplicate_component.errors[:bicycle_id]).to include("already has a #{component_name}")
    end
  end
end
