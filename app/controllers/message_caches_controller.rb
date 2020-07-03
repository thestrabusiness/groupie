class MessageCachesController < ApplicationController
  before_action :require_login
  before_action :require_group_membership

  def show
    render json: MessageCache.where(group_id: group_id).last&.serialize
  end

  def create
    message_cache = MessageCache.new(
      started_at: Time.current,
      group_id: group_id,
      started_by: current_user
    )

    if message_cache.save
      render json: message_cache.serialize
    else
      render json: message_cache.errors.full_messages, status: :unprocessable_entity
    end
  end

  private

  def require_group_membership
    unless current_user.group_member?(group_id)
      head :unauthorized
    end
  end

  def group_id
    params[:group_id]
  end
end
