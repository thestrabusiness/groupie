# frozen_string_literal: true

require "net/http"

module GroupMe
  class User < Model
    def find(access_token)
      self.data = FetchUser.perform(access_token)
      self
    end
  end

  class FetchUser < Api
    def self.perform(access_token)
      current_user_url = "#{BASE_API_URL}/users/me?token=#{access_token}"
      uri = URI(current_user_url)
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        return JSON.parse(response.body)["response"] 
      end

      {}
    end
  end
end
