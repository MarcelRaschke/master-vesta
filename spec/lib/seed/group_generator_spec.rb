# frozen_string_literal: true

require 'rails_helper'

describe GroupGenerator do
  describe '.generate' do
    it 'makes a new group' do
      draw = create(:draw)
      draw.suites << create(:suite, size: 3)
      expect { described_class.generate(draw: draw) }.to \
        change { Group.count }.by(1)
    end
  end
end
