# frozen_string_literal: true

require "net/http"

module GroupMe
  class FetchMessagesSince < Base
    attr_accessor :group_id, :access_token

    MESSAGE_LIMIT = 100
    SLEEP_DURATION = 0.5

    def self.perform(access_token, group_id, after_id)
      new(access_token, group_id).perform(after_id, [])
    end

    def initialize(access_token, group_id)
      @group_id = group_id
      @access_token = access_token
    end

    def perform(after_id, acc = [])
      uri = URI(messages_url(after_id))
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        message_data = JSON.parse(response.body)["response"]

        if message_data.empty?
          acc
        else
          messages = message_data.map { |message| Message.new(message) }
          next_after_id = messages.first.id
          sleep SLEEP_DURATION
          perform(next_after_id, acc + messages)
        end
      end
    end

    private

    def messages_url(after_id)
      [
        "#{BASE_API_URL}/groups/#{group_id}/messages?",
        token_param,
        limit_param,
        after_id_param(after_id)
      ].join("&")
    end

    def token_param
      "token=#{access_token}"
    end

    def limit_param
      "limit=#{MESSAGE_LIMIT}"
    end

    def after_id_param(after_id)
      "after_id=#{after_id}"
    end
  end
end
