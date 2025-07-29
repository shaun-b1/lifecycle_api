require 'rails_helper'

RSpec.describe Api::V1::Bicycle, type: :model do
  let(:user) { create(:user) }
  let(:bicycle) { build(:bicycle, user: user) }

  describe "validations" do
  end

  describe "associations" do
    it { should belong_to(:user).required }

    it { should have_one(:chain).conditions(status: "active").dependent(:destroy) }
    it { should have_one(:cassette).conditions(status: "active").dependent(:destroy) }
    it { should have_one(:chainring).conditions(status: "active").dependent(:destroy) }
    it { should have_many(:tires).conditions(status: "active").dependent(:destroy) }
    it { should have_many(:brakepads).conditions(status: "active").dependent(:destroy) }

    it { should have_many(:all_chains).dependent(:destroy) }
    it { should have_many(:all_cassettes).dependent(:destroy) }
    it { should have_many(:all_chainrings).dependent(:destroy) }
    it { should have_many(:all_tires).dependent(:destroy) }
    it { should have_many(:all_brakepads).dependent(:destroy) }

    it { should have_many(:services).dependent(:destroy) }
    it { should have_many(:component_replacements).through(:services) }
    it { should have_many(:maintenance_actions).through(:services) }
  end
end
