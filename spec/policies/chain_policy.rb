require 'rails_helper'

RSpec.describe ChainPolicy do
  subject { described_class }
  it_behaves_like "a component policy"
end
