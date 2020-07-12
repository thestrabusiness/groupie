# frozen_string_literal: true

require "net/http"

module GroupMe
  class FetchAllMessages
    SLEEP_DURATION = 0.5

    def self.perform(access_token, group_id)
      before_id = nil
      messages = []

      loop do
        message_data = MessageFetcher.perform(access_token, group_id, { before_id: before_id })
        break if message_data.empty?

        messages += message_data.map { |message| Message.new(message) }
        before_id = messages.last.id
        sleep SLEEP_DURATION
      end

      messages
    end
  end
end
