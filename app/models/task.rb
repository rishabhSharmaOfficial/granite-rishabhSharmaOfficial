# frozen_string_literal: true

class Task < ApplicationRecord
  RESTRICTED_ATTRIBUTES = %i[title task_owner_id assigned_user_id]
  MAX_TITLE_LENGTH = 125

  enum progress: { pending: "pending", completed: "completed" }
  enum status: { unstarred: "unstarred", starred: "starred" }

  belongs_to :assigned_user, foreign_key: "assigned_user_id", class_name: "User"
  belongs_to :task_owner, foreign_key: "task_owner_id", class_name: "User"
  has_many :comments, dependent: :destroy

  validates :title, presence: true, length: { maximum: MAX_TITLE_LENGTH }
  validates :slug, uniqueness: true
  validate :slug_not_changed

  before_create :set_slug
  after_create :log_task_details
  # before_validation :set_title
  # before_save :change_title

  private

    def set_slug
      title_slug = title.parameterize
      regex_pattern = "slug #{Constants::DB_REGEX_OPERATOR} ?"
      latest_task_slug = Task.where(
        regex_pattern,
        "#{title_slug}$|#{title_slug}-[0-9]+$"
      ).order("LENGTH(slug) DESC", slug: :desc).first&.slug
      slug_count = 0
      if latest_task_slug.present?
        slug_count = latest_task_slug.split("-").last.to_i
        only_one_slug_exists = slug_count == 0
        slug_count = 1 if only_one_slug_exists
      end
      slug_candidate = slug_count.positive? ? "#{title_slug}-#{slug_count + 1}" : title_slug
      self.slug = slug_candidate
    end

    def slug_not_changed
      if slug_changed? && self.persisted?
        errors.add(:slug, t("task.slug.immutable"))
      end
    end

    def self.of_status(progress)
      if progress == :pending
        starred = pending.starred.order("updated_at DESC")
        unstarred = pending.unstarred.order("updated_at DESC")
      else
        starred = completed.starred.order("updated_at DESC")
        unstarred = completed.unstarred.order("updated_at DESC")
      end
      starred + unstarred
    end

    def log_task_details
      TaskLoggerJob.perform_later(self)
    end

  # def set_title
  #   self.title = "Pay electricity bill"
  # end

  # def change_title
  #   self.title = "Pay electricity & TV bill"
  # end
end
