# frozen_string_literal: true

require "net/http"

module GroupMe
  class FetchAllMessages
    SLEEP_DURATION = 0.5

    attr_accessor :access_token, :group_id

    def initialize(access_token, group_id)
      @access_token = access_token
      @group_id = group_id
    end

    def self.perform(access_token, group_id)
      new(access_token, group_id).perform
    end

    def perform
      before_id = nil

      loop do
        message_data = MessageFetcher.perform(access_token, group_id, { before_id: before_id })
        break if message_data.empty?

        save_messages(message_data)
        before_id = message_data.last["id"]
        sleep SLEEP_DURATION
      end
    end

    private

    def save_messages(message_data)
      messages_attributes = message_data.map do |data|
        {
          id: data["id"],
          group_id: data["group_id"],
          user_id: data["user_id"],
          avatar_url: data["avatar_url"],
          text: data["text"],
          sender_name: data["name"],
          favorited_by: data["favorited_by"],
          favorites_count: data["favorited_by"].size,
          attachments: data["attachments"],
          raw_message: data,
          created_at: Time.at(data["created_at"]).to_datetime,
          updated_at: Time.current
        }
      end
      Message.upsert_all(messages_attributes)
    end
  end
end
