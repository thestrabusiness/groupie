class SessionsController < ApplicationController
  def create
    user_data = GroupMe::User.find(access_token)
    user = find_or_create_user(user_data)
    sign_in(user)
    redirect_to root_path
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

  def access_token
    params[:access_token]
  end
end
