require 'net/http'

module GroupMe
  class FetchMessages < Base
    attr_accessor :group_id

    def self.perform(access_token, group_id)
      @group_id = group_id
      new.perform(access_token, 1, [])
    end

    def perform(access_token, page, acc = [])
      uri = URI(messages_url(access_token, page))
      response = Net::HTTP.get_response(uri)

      if response.code == '200'
        message_data = JSON.parse(response.body)['response']

        if message_data.empty?
          acc
        else
          messages = message_data.map { |message| Message.new(message) }
          perform(access_token, page + 1, acc + messages)
        end
      end
    end

    private

    def messages_url(access_token, page)
      "#{BASE_API_URL}/groups/#{group_id}/messages?token=#{access_token}&page=#{page}&limit=100"
    end
  end
end
