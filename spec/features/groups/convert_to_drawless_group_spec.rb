# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Convert to drawless group' do
  let(:draw) { create(:draw_with_members, status: 'group_formation') }
  let(:group) { create(:full_group, leader: draw.students.first) }

  before { log_in create(:admin) }

  it 'can be performed' do
    visit draw_group_path(group.draw, group)
    click_on 'Make special group'
    expect(page).to have_css('.flash-success',
                             text: /is now a special group/)
  end
end
