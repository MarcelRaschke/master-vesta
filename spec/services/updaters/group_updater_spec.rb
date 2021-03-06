# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupUpdater do
  context 'size validations' do
    it 'must be available in the draw' do
      group = create(:open_group, size: 2)
      allow(group.draw).to receive(:open_suite_sizes).and_return([2])
      p = instance_spy('ActionController::Parameters', to_h: { size: 4 })
      expect(described_class.update(group: group, params: p)[:msg]).to \
        have_key(:error)
    end
    it 'succeeds when it is an existing suite size' do
      group = create(:open_group, size: 2)
      allow(group.draw).to receive(:open_suite_sizes).and_return([4])
      p = instance_spy('ActionController::Parameters', to_h: { size: 4 })
      expect(described_class.update(group: group, params: p)[:msg]).to \
        have_key(:success)
    end
  end

  describe '#update' do
    context 'group is full' do
      let(:group) { create(:open_group, size: 2) }
      let(:to_remove) do
        create(:student_in_draw, intent: 'on_campus', draw: group.draw)
      end

      it 'deletes memberships for users being removed before updating' do
        p = mock_remove_parameters(to_remove)
        create(:membership, user: to_remove, group: group)
        expect { described_class.update(group: group, params: p) }.to \
          change(Membership, :count).by(-1)
      end
      def mock_remove_parameters(to_remove)
        instance_spy('ActionController::Parameters',
                     to_h: { 'remove_ids' => [to_remove.id.to_s] })
      end
    end

    context 'users being added' do
      let(:group) { create(:open_group, size: 2) }
      let(:to_add) { create(:student_in_draw, draw: group.draw) }

      it 'updates their intent to on_campus if necessary' do
        to_add.draw_membership.update!(intent: 'undeclared')
        p = mock_add_parameters(to_add)
        described_class.update(group: group, params: p)
        expect(to_add.draw_membership.reload.intent).to eq('on_campus')
      end
      it 'updates even if user has pending invitations' do
        create(:membership, user: to_add, status: 'invited', group: group)
        p = mock_add_parameters(to_add)
        described_class.update(group: group, params: p)
        expect(group.members).to include(to_add)
      end
      def mock_add_parameters(to_add)
        instance_spy('ActionController::Parameters',
                     to_h: { 'member_ids' => [to_add.id.to_s] })
      end
    end

    context 'size is locked' do
      let(:group) { create(:full_group, size: 2) }

      it 'deletes the empty size key from the params' do
        p = instance_spy('ActionController::Parameters',
                         to_h: { 'leader' => group.members.last.id.to_s,
                                 'size' => '' })
        result = described_class.update(group: group, params: p)
        expect(result[:msg]).to have_key(:success)
      end
    end

    context 'users being removed' do
      it 'does not remove the leader if passed' do
        group = create(:open_group, size: 2)
        p = instance_spy('ActionController::Parameters',
                         to_h: { 'remove_ids' => [group.leader.id.to_s] })
        expect { described_class.update(group: group, params: p) }.not_to \
          change(Membership, :count)
      end
    end

    context 'success' do
      it 'sets to the :redirect_object to the group and draw' do
        group = instance_spy('group', update!: true)
        p = instance_spy('ActionController::Parameters', to_h: { size: 4 })
        result = described_class.update(group: group, params: p)
        expect(result[:redirect_object]).to eq([group.draw, group])
      end
      it 'sets the :group to the group' do
        group = instance_spy('group', update!: true)
        p = instance_spy('ActionController::Parameters', to_h: { size: 4 })
        result = described_class.update(group: group, params: p)
        expect(result[:record]).to eq(group)
      end
      it 'sets a success message' do
        group = instance_spy('group', update!: true)
        p = instance_spy('ActionController::Parameters', to_h: { size: 4 })
        result = described_class.update(group: group, params: p)
        expect(result[:msg]).to have_key(:success)
      end
      it 'can add members and increase the size' do
        group = expandable_group(size: 1)
        user = create(:student_in_draw, draw: group.draw)
        params = { size: 2, member_ids: [user.id.to_s] }
        described_class.update(group: group, params: params)
        expect(group.members).to include(user)
      end
    end
    context 'failure' do
      let!(:group) do
        build_stubbed(:group).tap do |g|
          memberships = instance_spy('ActiveRecord::CollectionProxy',
                                     where: true)
          allow(g).to receive(:memberships).and_return(memberships)
          allow(g).to receive(:reload)
          allow(g).to receive(:update!)
            .and_raise(ActiveRecord::RecordInvalid.new(g))
        end
      end

      it 'sets the :redirect_object to nil' do
        p = instance_spy('ActionController::Parameters', to_h: { size: 4 })
        result = described_class.update(group: group, params: p)
        expect(result[:redirect_object]).to be_nil
      end
      it 'sets an error message' do
        p = instance_spy('ActionController::Parameters', to_h: { size: 4 })
        result = described_class.update(group: group, params: p)
        expect(result[:msg]).to have_key(:error)
      end
    end
  end
  def expandable_group(size: 1)
    create(:full_group, size: size).tap do |g|
      g.draw.suites << create(:suite_with_rooms, rooms_count: size + 1)
    end
  end
end
