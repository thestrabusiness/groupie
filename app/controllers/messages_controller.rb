# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :require_login

  def index
    if current_user.group_member?(params[:group_id])
      render json: Message.where(group_id: params[:group_id]).limit(20)
    else
      head :unauthorized
    end
  end
end
