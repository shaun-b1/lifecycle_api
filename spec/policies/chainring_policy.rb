require 'rails_helper'

RSpec.describe ChainringPolicy do
  subject { described_class }
  it_behaves_like "a component policy"
end
