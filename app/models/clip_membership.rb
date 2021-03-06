# frozen_string_literal: true

# Join model between groups and clips.
# @attr group [Group] The group of the membership.
# @attr clip [Clip] The clip of the membership.
# @attr confirmed [Boolean] Confirmation for membership. Defaults to false.
class ClipMembership < ApplicationRecord
  belongs_to :group
  belongs_to :clip

  validates :group, presence: true, uniqueness: { scope: :clip }
  validates :clip, presence: true

  after_save :destroy_pending, if: ->() { confirmed? }

  after_destroy :run_clip_cleanup

  private

  def destroy_pending
    group.clip_memberships.where.not(id: id).map(&:destroy!)
  end

  def run_clip_cleanup
    clip.cleanup!
  end
end
