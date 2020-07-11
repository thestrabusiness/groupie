module GroupMe
  class GetLatestMessageId
    def self.perform(access_token, group_id)
      message_data = MessageFetcher.perform(access_token, group_id)
      messages = message_data.map { |message| Message.new(message) }

      messages.last.id
    end
  end
end
