class SessionsController < ApplicationController
  before_action :require_login, only: :show

  def show
    render json: current_user_info
  end

  def create
    user_data = GroupMe::User.find(access_token)
    user = find_or_create_user(user_data)
    sign_in(user)
    redirect_to root_path
  end

  private

  def access_token
    params[:access_token]
  end

  def find_or_create_user(user_data)
    User.find_by(id: user_data['id']) ||
      User.create(
        id: user_data['id'],
        name: user_data['name'],
        email: user_data['email'],
        image_url: user_data['image_url'],
        access_token: access_token
      )
  end

  def current_user_info
    { name: current_user.name, access_token: current_user.access_token }
  end
end
