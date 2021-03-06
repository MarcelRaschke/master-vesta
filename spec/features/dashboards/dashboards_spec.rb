# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Dashboards' do
  context 'admin' do
    it 'renders' do
      create_draws
      log_in create(:admin)
      expect(page).to have_content('Vesta')
    end

    def create_draws
      create(:draw_with_members, status: 'draft')
      create(:oversubscribed_draw, status: 'group_formation')
      create(:draw_in_lottery)
      create(:draw_in_selection)
      # TODO: results draw
    end
  end

  context 'student' do
    shared_examples 'renders' do
      it do
        log_in student
        expect(page).to have_content('Vesta')
      end
    end

    context 'with draw' do
      context 'with deadlines' do
        it_behaves_like 'renders' do
          let(:student) do
            create(:student_in_draw).tap do |s|
              s.draw.update(intent_deadline: Time.zone.tomorrow,
                            locking_deadline: Time.zone.tomorrow + 1.day)
            end
          end
        end
      end
    end

    context 'without group' do
      it_behaves_like 'renders' do
        let(:student) { create(:student_in_draw) }
      end
    end
    context 'with group no suite' do
      it_behaves_like 'renders' do
        let(:student) { create(:group).leader }
      end
    end
    context 'with suite no room' do
      it_behaves_like 'renders' do
        let(:student) { create(:group_with_suite).leader }
      end
    end
    context 'with room' do
      it_behaves_like 'renders' do
        let(:student) do
          g = create(:group_with_suite)
          s = g.leader
          create(:room_assignment, room: g.suite_assignment.suite.rooms.first,
                                   user: s.reload)
          s
        end
      end
    end
  end
end
