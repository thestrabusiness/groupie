require 'net/http'

module GroupMe
  class FetchAllMessages < Base
    attr_accessor :group_id, :access_token

    MESSAGE_LIMIT = 100.freeze
    SLEEP_DURATION = 0.5.freeze

    def self.perform(access_token, group_id)
      new(access_token, group_id).perform(nil, [])
    end

    def initialize(access_token, group_id)
      @group_id = group_id
      @access_token = access_token
    end

    def perform(before_id, acc)
      uri = URI(messages_url(before_id))
      response = Net::HTTP.get_response(uri)

      if response.code == '200'
        message_data = JSON.parse(response.body)['response']['messages']
        messages = message_data.map { |message| Message.new(message) }
        next_before_id = messages.last.id
        sleep SLEEP_DURATION
        perform(next_before_id, acc + messages)
      else
        acc
      end
    end

    private

    def messages_url(before_id)
      [
        "#{BASE_API_URL}/groups/#{group_id}/messages?#{token_param}",
        limit_param,
        before_id_param(before_id)
      ].reject(&:empty?).join("&")
    end

    def token_param
      "token=#{access_token}"
    end

    def limit_param
      "limit=#{MESSAGE_LIMIT}"
    end

    def before_id_param(before_id)
      before_id.present? ? "before_id=#{before_id}" : ""
    end
  end
end
