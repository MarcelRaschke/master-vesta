# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'basic validations' do
    subject { build(:group) }

    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to allow_value(1).for(:size) }
    it { is_expected.not_to allow_value(0).for(:size) }
    it { is_expected.not_to allow_value(-1).for(:size) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to belong_to(:leader_draw_membership) }
    it { is_expected.to have_one(:leader).through(:leader_draw_membership) }
    it { is_expected.to validate_presence_of(:leader_draw_membership) }
    it { is_expected.to belong_to(:draw) }
    it { is_expected.to have_one(:clip_membership) }
    it { is_expected.to have_one(:clip).through(:clip_membership) }
    it { is_expected.to have_one(:suite_assignment) }
    it { is_expected.to have_one(:suite).through(:suite_assignment) }
    it { is_expected.to belong_to(:lottery_assignment) }
    it { is_expected.to have_many(:memberships) }
    it { is_expected.to have_many(:clip_memberships) }
    it { is_expected.to have_many(:full_memberships) }
    it do
      is_expected.to have_many(:draw_memberships).through(:full_memberships)
    end
    it { is_expected.to have_many(:members).through(:draw_memberships) }
    it { is_expected.not_to allow_value(-1).for(:memberships_count) }
    it { is_expected.to validate_presence_of(:transfers) }
    it { is_expected.not_to allow_value(-1).for(:transfers) }
    it { is_expected.to delegate_method(:suite_number).to(:suite).as(:number) }
    it do
      is_expected.to delegate_method(:lottery_number).to(:lottery_assignment)
                                                     .as(:number)
    end
  end

  describe 'size validations' do
    it 'must not have more members than the size' do
      group = create(:full_group, size: 2)
      group.size = 1
      expect(group.valid?).to be_falsey
    end
    it 'must be positive' do
      group = create(:full_group, size: 2)
      group.size = 0
      expect(group.valid?).to be_falsey
    end
    it 'must be numeric' do
      group = create(:full_group, size: 2)
      group.size = 'a'
      expect(group.valid?).to be_falsey
    end
    it 'also validates during creation' do
      leader, student = create_pair(:student_in_draw)
      group = described_class.new(size: 1, leader: leader,
                                  draw_memberships: [student.draw_membership])
      group.save
      expect(group.persisted?).to be_falsey
    end
    it 'takes transfers into account' do
      group = create(:open_group, size: 2, transfers: 1)
      expect(group).to be_closed
    end
  end

  describe 'status validations' do
    it 'can only be locked if the number of members match the size' do
      group = build(:open_group)
      group.status = 'locked'
      expect(group.valid?).to be_falsey
    end
    it 'can only be locked if all memberships are locked' do
      # finalizing locks the leader only, not any of the members
      group = create(:finalizing_group, size: 2)
      group.status = 'locked'
      expect(group.valid?).to be_falsey
    end
    it 'cannot be closed when there are less members than the size' do
      group = build(:open_group)
      group.status = 'closed'
      expect(group.valid?).to be_falsey
    end
    it 'takes transfers into account' do
      group = create(:open_group, size: 2, transfers: 1)
      group.status = 'open'
      expect(group).not_to be_valid
    end
    it 'cannot be open when members match the size' do
      group = create(:full_group, size: 2)
      group.status = 'open'
      expect(group.valid?).to be_falsey
    end
  end

  describe 'lottery validations' do
    context 'when clipped' do
      let(:clip) { create(:clip) }
      let(:draw) { clip.draw }
      let(:group) { clip.groups.first }

      before { draw.lottery! }

      it 'can create a lottery assignment for a clip' do
        lottery = create(:lottery_assignment, :defined_by_clip, clip: clip)
        expect(group.reload.lottery_assignment_id).to eq(lottery.id)
      end

      it 'cannot assign the group to a lottery not belonging to the clip' do
        lottery = create(:lottery_assignment, draw: draw)
        expect { group.update!(lottery_assignment_id: lottery.id) }.to \
          raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when not clipped' do
      let(:group) { create(:locked_group) }

      before { group.draw.lottery! }

      it 'can create a lottery assignment for a group' do
        lottery = create(:lottery_assignment, :defined_by_group, group: group)
        expect(group.reload.lottery_assignment_id).to eq(lottery.id)
      end
    end

    it 'cannot change a lottery_assignment once set' do
      lottery = create(:lottery_assignment)
      new_lottery = create(:lottery_assignment)
      group = lottery.group
      expect(group.update(lottery_assignment_id: new_lottery.id)).to be_falsey
    end

    it 'raises an error if attempt to edit lottery_assignment' do
      lottery, new_lottery = create_pair(:lottery_assignment)
      group = lottery.group
      group.update(lottery_assignment_id: new_lottery.id)
      expect(group.errors[:base])
        .to include('Cannot edit lottery assignment once set')
    end

    it 'can remove a lottery assignment if set' do
      lottery = create(:lottery_assignment)
      group = lottery.group
      expect(group.update(lottery_assignment_id: nil)).to be_truthy
    end

    it 'must be the only group unless in a clip' do
      lottery = create(:lottery_assignment)
      group = create(:locked_group, :defined_by_draw, draw: lottery.draw)
      group.lottery_assignment_id = lottery.id
      expect(group.valid?).to be_falsey
    end
  end

  it 'destroys dependent memberships on destruction' do
    group = create(:drawless_group)
    membership_ids = group.memberships.map(&:id)
    group.destroy
    expect { Membership.find(membership_ids) }.to \
      raise_error(ActiveRecord::RecordNotFound)
  end

  it 'clears suite assignments on destruction' do
    group = create(:locked_group)
    suite = create(:suite, group: group)
    expect { group.destroy }.to change { suite.reload.group }.to(nil)
  end

  it 'updates status when changing transfer students' do
    group = create(:open_group, size: 2)
    group.update(transfers: 1)
    expect(group.reload).to be_full
  end

  describe 'leader is included as a member' do
    it do
      group = create(:group)
      expect(group.members).to include(group.leader)
    end
  end

  describe '#name' do
    let(:group) { build_stubbed(:group) }
    let(:leader) { instance_spy('user', full_name: 'First Last') }

    before { allow(group).to receive(:leader).and_return(leader) }

    context 'default' do
      it "includes the leader's name" do
        expect(group.name).to eq("First Last's Group")
      end

      it 'ignores unexpected options' do
        expect(group.name(:foo)).to eq("First Last's Group")
      end
    end

    context 'with just size' do
      it 'includes the group size' do
        allow(group).to receive(:size).and_return(2)
        allow(Suite).to receive(:size_str).with(2).and_return('double')
        expect(group.name(:with_size)).to \
          eq("First Last's Group (double)")
      end
    end

    context 'with just class year' do
      it "includes the leader's class year" do
        allow(leader).to receive(:class_year).and_return(2017)
        expect(group.name(:with_year)).to \
          eq("First Last's Group (2017)")
      end
    end

    context 'with both size and class year' do
      it "includes both the group size and leader's class year" do
        allow(group).to receive(:size).and_return(2)
        allow(Suite).to receive(:size_str).with(2).and_return('double')
        allow(leader).to receive(:class_year).and_return(2017)
        expect(group.name(:with_size, :with_year)).to \
          eq("First Last's Group (double, 2017)")
      end
    end
  end

  describe '#requests' do
    it 'returns an array of users who have requested to join' do
      group = create(:open_group)
      user = create(:student_in_draw, draw: group.draw)
      m = create(:membership, group: group, user: user, status: 'requested')
      expect(group.requests).to eq([m])
    end
  end

  describe '#invitations' do
    it 'returns an array of users who have been invited to join' do
      group = create(:open_group)
      user = create(:student_in_draw, draw: group.draw)
      m = create(:membership, group: group, user: user, status: 'invited')
      expect(group.invitations).to eq([m])
    end
  end

  describe '#pending_memberships' do
    let(:group) { create(:open_group) }

    it 'returns invitations but not accepted memberships' do
      user = create(:student_in_draw, draw: group.draw)
      m = create(:membership, group: group, user: user, status: 'invited')
      expect(group.pending_memberships).to match([m])
    end
    it 'returns requests but not accepted memberships' do
      user = create(:student_in_draw, draw: group.draw)
      m = create(:membership, group: group, user: user, status: 'requested')
      expect(group.pending_memberships).to match([m])
    end
  end

  describe '#members' do
    it 'returns only members with an accepted membership' do
      group = create(:open_group)
      create_potential_member(status: 'invited', group: group)
      create_potential_member(status: 'requested', group: group)
      expect(group.reload.members.map(&:id)).to eq([group.leader.id])
    end

    def create_potential_member(status:, group:)
      u = create(:student_in_draw, draw: group.draw)
      create(:membership, user: u, group: group, status: status)
      u
    end
  end

  describe '#removable_members' do
    it 'returns all accepted members except for the leader' do
      group = create(:full_group, size: 2)
      expect(group.removable_members.map(&:id)).not_to include(group.leader.id)
    end
  end

  describe '#remove_members!' do
    it 'removes members except leader' do
      group = create(:full_group, size: 3)
      ids = group.members.map(&:id)
      expect { group.remove_members!(ids: ids) }.to \
        change { group.memberships_count }.from(3).to(1)
    end
    it 'changes the group status from full to open' do
      group = create(:full_group, size: 2)
      ids = group.members.map(&:id)
      expect { group.remove_members!(ids: ids) }.to \
        change { group.status }.from('closed').to('open')
    end
    it 'deletes membership object' do
      group = create(:full_group, size: 2)
      last_membership_id = group.memberships.last.id
      group.remove_members!(ids: [group.members.last.id])
      expect { Membership.find(last_membership_id) }.to \
        raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#destroy' do
    it 'removes clip_memberships if they exist' do
      group = create(:clip, groups_count: 3).groups.first
      m = group.clip_membership
      group.destroy!
      expect { m.reload } .to raise_error(ActiveRecord::RecordNotFound)
    end
    it 'destroys the lottery assignment if not clipped' do
      group = create(:lottery_assignment).groups.first
      expect { group.destroy! }.to change { LotteryAssignment.count }.by(-1)
    end
    it 'does not destroy the lottery assignment if clipped' do
      clip = create(:clip, draw: create(:draw, status: 'lottery'))
      group = create(:lottery_assignment, :defined_by_clip, clip: clip).groups
                                                                       .first
      expect { group.destroy! }.not_to change { LotteryAssignment.count }
    end
  end

  describe '#cleanup!' do
    it 'deletes the group if there is no member left' do
      group = create(:group, size: 1)
      group.memberships.first.delete
      group.reload.cleanup!
      expect { group.reload } .to raise_error(ActiveRecord::RecordNotFound)
    end
    it 'does nothing if there is at least one member left' do
      group = create(:full_group, size: 2)
      group.memberships.first.delete
      group.reload.cleanup!
      expect(group.reload).to eq(group)
    end
  end

  describe '#locked_members' do
    it 'returns memberships that are locked' do
      group = create(:finalizing_group)
      expect(group.locked_members).to eq([group.leader])
    end
  end

  describe '#lockable?' do
    it 'returns true when all members are locked, and group is full' do
      group = create(:finalizing_group)
      group.full_memberships.reject(&:locked).each do |m|
        m.update(locked: true)
      end
      expect(group.reload).to be_lockable
    end
  end

  describe '#unlockable?' do
    it 'returns true when there are _any_ locked members and no suite' do
      group = create(:finalizing_group)
      group.update!(status: 'closed')
      expect(group.reload).to be_unlockable
    end
    it 'returns false if the group has a suite assigned' do
      group = create(:locked_group)
      allow(group).to receive(:suite)
        .and_return(instance_spy('suite', nil?: false))
      expect(group).not_to be_unlockable
    end
    it 'returns false if there are no locked members' do
      group = create(:open_group)
      expect(group).not_to be_unlockable
    end
  end

  describe '#invited_to_clip?' do
    it 'returns true if there is an open invite' do
      clip = create(:clip)
      group = clip.groups.first
      group.clip_membership.update!(confirmed: false)
      expect(group.invited_to_clip?(clip)).to eq(true)
    end
    it 'returns false if there is an accepted invite' do
      clip = create(:clip)
      group = clip.groups.first
      expect(group.invited_to_clip?(clip)).to eq(false)
    end
    it 'returns false if there is no invite' do
      group = create(:group)
      clip = create(:clip)
      expect(group.invited_to_clip?(clip)).to eq(false)
    end
  end

  describe 'clip association' do
    it 'only joins on confirmed memberships' do
      clip = create(:clip)
      group = clip.groups.first
      create_unconfirmed_clip_membership(group: group)
      expect(group.reload.clip).to eq(clip)
    end
  end

  describe 'clip_memberships' do
    it 'are cleared on draw change' do
      clip = create(:clip, groups_count: 3)
      group = clip.groups.first
      create_unconfirmed_clip_membership(group: group)
      group.update!(draw_id: nil)
      expect(group.reload.clip_memberships.empty?).to be_truthy
    end
  end

  describe 'group factories' do
    context 'create valid groups' do
      it 'and defaults to :defined_by_leader with the :group factory' do
        group = create(:group)
        expect(group).to be_persisted
      end
      it 'and uses :defined_by_draw trait in :group_from_draw factory' do
        group = create(:group_from_draw)
        expect(group).to be_persisted
      end
    end
  end

  it 'deletes the lottery assignment on group deletion' do
    lottery = create(:lottery_assignment)
    expect { lottery.group.destroy }.to \
      change { LotteryAssignment.count }.by(-1)
  end

  describe '.order_by_lottery' do
    it 'orders the collection of groups by their lottery numbers' do
      groups = create(:draw_in_selection, groups_count: 3).groups
      lottery = groups.map(&:lottery_number).sort!
      expect(groups.order_by_lottery.map(&:lottery_number)).to eq(lottery)
    end
  end

  describe '.active' do
    it 'returns groups with active leader_draw_memberships' do
      group1, group2 = create_pair(:group)
      group2.leader_draw_membership.update!(active: false)
      expect(described_class.active).to eq([group1])
    end
  end

  describe '#lottery_number' do
    it 'is nil when no lottery assignment' do
      group = build_stubbed(:group)
      expect(group.lottery_number).to be_nil
    end
    it 'returns the number of the lottery assignment' do
      lottery = create(:lottery_assignment)
      group = lottery.group
      expect(group.lottery_number).to eq(lottery.number)
    end
  end

  def create_unconfirmed_clip_membership(group:)
    new_clip = create(:clip, draw: group.draw)
    create(:clip_membership, clip: new_clip, group: group, confirmed: false)
  end
end
