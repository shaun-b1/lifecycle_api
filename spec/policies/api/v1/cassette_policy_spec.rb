require 'rails_helper'

RSpec.describe Api::V1::CassettePolicy do
  subject { described_class }
  it_behaves_like "a component policy"
end
