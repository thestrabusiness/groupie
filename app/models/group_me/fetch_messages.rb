require 'net/http'

module GroupMe
  class FetchMessages < Base
    attr_accessor :group_id, :after_id, :access_token

    MESSAGE_LIMIT = 100.freeze
    SLEEP_DURATION = 0.5.freeze

    def self.perform(access_token, group_id, after_id = nil)
      new(access_token, group_id, after_id).perform(1, [])
    end

    def initialize(access_token, group_id, after_id)
      @group_id = group_id
      @after_id = after_id
      @access_token = access_token
    end

    def perform(page, acc = [])
      uri = URI(messages_url(page))
      response = Net::HTTP.get_response(uri)

      if response.code == '200'
        message_data = JSON.parse(response.body)['response']

        if message_data.empty?
          acc
        else
          messages = message_data.map { |message| Message.new(message) }
          sleep SLEEP_DURATION
          perform(page + 1, acc + messages)
        end
      end
    end

    private

    def messages_url(page)
      [
        "#{BASE_API_URL}/groups/#{group_id}/messages?page=#{page}",
        token_param,
        limit_param,
        after_id_param
      ].reject(&:empty?).join("&")
    end

    def token_param
      "token=#{access_token}"
    end

    def limit_param
      "limit=#{MESSAGE_LIMIT}"
    end

    def after_id_param
      after_id.present? ? "after_id=#{after_id}" : ""
    end
  end
end
