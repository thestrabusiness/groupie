require 'net/http'

module GroupMe
  class User
    def self.find(access_token)
      uri = URI("https://api.groupme.com/v3/users/me?token=#{access_token}")
      response = Net::HTTP.get_response(uri)

      if response.code == '200'
        JSON.parse(response.body)['response']
      end
    end
  end
end
