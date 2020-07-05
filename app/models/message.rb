class Message < ApplicationRecord
  belongs_to :group

  before_save :update_favorites_count

  scope :by_favorite_count, -> { order(favorites_count: :desc) }

  def serialize
    {
      id: id,
      created_at: created_at.to_i,
      text: text,
      avatar_url: avatar_url,
      favorites_count: favorites_count,
      sender_name: sender_name
    }
  end

  private

  def update_favorites_count
    self.favorites_count = favorited_by.size
  end
end
