class MostLikedMessagesController < ApplicationController
  before_action :require_login

  def index
    if current_user.group_ids.include?(params[:group_id])
      limit = params[:limit] || 10

      render json: Message.where(group_id: group_id).by_favorite_count.limit(limit)
    else
      head :unauthorized
    end
  end
end
