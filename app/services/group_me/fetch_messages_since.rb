# frozen_string_literal: true

require "net/http"

module GroupMe
  class FetchMessagesSince
    SLEEP_DURATION = 0.5

    def self.perform(access_token, group_id, after_id)
      messages = []

      loop do
        message_data = MessageFetcher.perform(access_token, group_id, { after_id: after_id })
        break if message_data.empty?

        messages += message_data.map { |message| Message.new(message) }
        after_id = messages.first.id
        sleep SLEEP_DURATION
      end

      messages
    end
  end
end
