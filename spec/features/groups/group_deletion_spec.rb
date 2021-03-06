# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Group deletion' do
  let(:group) { create(:group).tap { |g| g.draw.group_formation! } }

  before { log_in create(:admin) }

  it 'succeeds' do
    msg = "Group #{group.name} deleted."
    visit draw_group_path(group.draw, group)
    click_on 'Disband'
    expect(page).to have_content(msg)
  end
end
