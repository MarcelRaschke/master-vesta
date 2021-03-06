# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Email export' do
  let!(:draw) { create(:draw_with_members, status: 'group_formation') }
  let!(:group) { create(:locked_group, leader: draw.students.last) }

  before { log_in create(:admin) }

  it 'returns all the group leader e-mails in a given draw' do
    visit new_email_export_path
    select draw.name, from: 'email_export_draw_id'
    click_on 'Get e-mails'
    expect(page).to have_content(group.leader.email)
  end
end
