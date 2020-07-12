# frozen_string_literal: true

class MessageCacheJob < ApplicationJob
  def perform(message_cache_id, access_token)
    message_cache = MessageCache.find(message_cache_id)
    group = message_cache.group
    cache_messages(access_token, group)
    message_cache.update(ended_at: Time.current)
  end

  private

  def cache_messages(access_token, group)
    if group.messages.present?
      GroupMe::FetchMessagesSince.perform(access_token, group.id,
                                          group.last_message_id)
    else
      GroupMe::FetchAllMessages.perform(access_token, group.id)
    end
  end
end
