class MessageCache < ApplicationRecord
  belongs_to :started_by, class_name: 'User'
  belongs_to :group

  validates :started_at, :started_by, :group, presence: true
  validate :start_time_not_in_future
  validate :end_time_after_start_time
  validate :one_cache_per_day_per_group, on: :create

  after_create :enqueue_cache_job

  scope :for_last_day, -> { where("started_at >= ?", 24.hours.ago) }
  scope :running, -> { where(ended_at: nil) }

  def ended?
    ended_at.present? && ended_at <= Time.current
  end

  def serialize
    {
      id: id,
      started_at: started_at.to_i,
      ended_at: ended_at&.to_i,
    }
  end

  private

  def start_time_not_in_future
    return if started_at <= Time.current

    errors.add(:started_at, "must be in the past")
  end

  def end_time_after_start_time
    return if ended_at.nil? || ended_at > started_at

    errors.add(:ended_at, "must be after started_at")
  end

  def one_cache_per_day_per_group
    return unless group.message_caches.for_last_day.exists?

    errors.add(:group, "can only cache messages once per day")
  end

  def enqueue_cache_job
    MessageCacheJob.perform_later(id, started_by.access_token)
  end
end
