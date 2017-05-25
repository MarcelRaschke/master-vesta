# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SuiteCreator do
  context 'success' do
    it 'sucessfully creates a suite' do
      params = instance_spy('ActionController::Parameters', to_h: params_hash)
      expect(described_class.new(params).create![:redirect_object]).to \
        be_instance_of(Suite)
    end
    it 'returns the suite object' do
      params = instance_spy('ActionController::Parameters', to_h: params_hash)
      expect(described_class.new(params).create![:record]).to \
        be_instance_of(Suite)
    end
    it 'returns a success flash message' do
      params = instance_spy('ActionController::Parameters', to_h: params_hash)
      expect(described_class.new(params).create![:msg]).to have_key(:success)
    end
    def params_hash
      { number: 'L01', building: FactoryGirl.build(:building) }
    end
  end
  it 'does not create when given invalid params' do
    params = instance_spy('ActionController::Parameters', to_h: {})
    expect(described_class.new(params).create![:redirect_object]).to be_nil
  end
  it 'returns the suite even if invalid' do
    params = instance_spy('ActionController::Parameters', to_h: {})
    expect(described_class.new(params).create![:record]).to \
      be_instance_of(Suite)
  end
end
