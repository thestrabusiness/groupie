# frozen_string_literal: true

require "net/http"

module GroupMe
  class User < Base
    def find(access_token)
      uri = URI(current_user_url(access_token))
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        self.data = JSON.parse(response.body)["response"]
        self
      end
    end

    private

    def current_user_url(access_token)
      "#{BASE_API_URL}/users/me?token=#{access_token}"
    end
  end
end
