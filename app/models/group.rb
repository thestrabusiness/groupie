class Group < ApplicationRecord
  has_many :message_caches
  has_many :messages

  def last_message_id
    messages.order(created_at: :desc).first&.id
  end

  def messages_last_fetched_at
    message_caches.last&.ended_at
  end
end
