class MessageCacheJob < ApplicationJob
  def perform(message_cache_id, access_token)
    message_cache = MessageCache.find(message_cache_id)
    group = message_cache.group
    GroupMe::FetchMessages.perform(access_token, group.id, group.last_message_id)
    message_cache.update(ended_at: Time.current)
  end
end
