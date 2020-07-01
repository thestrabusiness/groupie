class Message < ApplicationRecord
  belongs_to :group

  before_save :update_favorites_count

  private

  def update_favorites_count
    self.favorites_count = favorited_by.size
  end
end
