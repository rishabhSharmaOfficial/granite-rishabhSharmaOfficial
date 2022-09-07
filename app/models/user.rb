# frozen_string_literal: true

class User < ApplicationRecord
  has_many :assigned_tasks, foreign_key: :assigned_user_id, class_name: "Task"

  MAX_NAME_LENGTH = 255

  validates :name, presence: true, length: { maximum: MAX_NAME_LENGTH }
end
