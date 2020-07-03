class MostLikedMessagesController < ApplicationController
  before_action :require_login

  def index
    if current_user.group_member?(group_id)
      limit = params[:limit] || 10
      messages = Message.where(group_id: group_id).by_favorite_count.limit(limit)

      render json: messages.map(&:serialize)
    else
      head :unauthorized
    end
  end

  private

  def group_id
    params[:group_id]
  end
end
