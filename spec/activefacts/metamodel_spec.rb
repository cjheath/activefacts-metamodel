require 'spec_helper'

describe ActiveFacts::Metamodel do
  it 'has a version number' do
    expect(ActiveFacts::Metamodel::VERSION).not_to be nil
  end

  it 'loads and can create a blank model' do
    c = ActiveFacts::API::Constellation.new(ActiveFacts::Metamodel)
  end
end
