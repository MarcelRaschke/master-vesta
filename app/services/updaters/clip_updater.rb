# frozen_string_literal: true

#
# Service object to update clips.
class ClipUpdater < Updater
  validates :group_ids,
            length: { minimum: 2,
                      too_short: 'There must be more than one group per clip.' }

  validate :freeze_draw_id, if: -> { params.key?(:draw_id) }
  validate :freeze_draw, if: -> { params.key?(:draw) }

  # Initialize a new ClipUpdater.
  #
  # @param clip [Clip] the clip to be updated
  # @param params [#to_h] the params with the new attributes
  def initialize(clip:, params:)
    super(object: clip, name_method: :name, params: params)
    @group_ids = if @params[:group_ids].present?
                   @params[:group_ids].reject(&:empty?)
                 else
                   []
                 end
    @clip_memberships = clip.clip_memberships
  end

  # Attempt to update the clip.
  #
  # @return [Hash{Symbol=>Clip,Hash}] a results hash with a message to set in
  #   the flash and either `nil` or the updated clip.
  def update
    return error(self) unless valid?
    ActiveRecord::Base.transaction do
      remove_clip_memberships
      create_clip_memberships
      confirm_unconfirmed
    end
    success
  rescue ActiveRecord::RecordInvalid => e
    error(e)
  end

  private

  attr_reader :group_ids, :clip_memberships

  def confirm_unconfirmed
    groups_to_be_confirmed.each do |g|
      cm = clip_memberships.where(group_id: g).first
      ClipMembershipUpdater.update(clip_membership: cm,
                                   params: { confirmed: true })
    end
  end

  def create_clip_memberships
    new_groups.each do |group_id|
      ClipMembership.create!(clip_id: object.id, group_id: group_id,
                             confirmed: true)
    end
  end

  def remove_clip_memberships
    groups_to_be_removed.each do |group_id|
      clip_memberships.where(group_id: group_id).first.destroy!
    end
  end

  def groups_to_be_confirmed
    unconfirmed_group_ids = clip_memberships.where(confirmed: false)
                                            .map(&:group_id).map(&:to_s)
    group_ids.select { |g| unconfirmed_group_ids.include?(g) }
  end

  def new_groups
    group_ids - clip_memberships.map(&:group_id).map(&:to_s)
  end

  def groups_to_be_removed
    clip_memberships.map(&:group_id).map(&:to_s) - group_ids
  end

  def freeze_draw_id
    return if params[:draw_id] == object.draw.id
    errors.add(:base, 'The draw of a clip cannot be changed.')
  end

  def freeze_draw
    return if params[:draw] == object.draw
    errors.add(:base, 'The draw of a clip cannot be changed.')
  end
end
