class MessageCacheJob < ApplicationJob
  def perform(message_cache_id, access_token)
    message_cache = MessageCache.find(message_cache_id)
    group = message_cache.group

    messages = fetch_messages(access_token, group)
    insert_messages(messages)
    message_cache.update(ended_at: Time.current)
  end

  private

  def fetch_messages(access_token, group)
    if group.messages.present?
      GroupMe::FetchMessagesSince.perform(access_token, group.id, group.last_message_id)
    else
      GroupMe::FetchAllMessages.perform(access_token, group.id)
    end
  end

  def insert_messages(messages)
    message_data = messages.map do |message|
      {
        id: message.id,
        group_id: message.group_id,
        user_id: message.user_id,
        avatar_url: message.avatar_url,
        text: message.text,
        favorited_by: message.favorited_by,
        favorites_count: message.favorited_by.size,
        attachments: message.attachments,
        raw_message: message.data,
        created_at: Time.at(message.created_at).to_datetime,
        updated_at: Time.current
      }
    end
    Message.upsert_all(message_data)
  end
end
