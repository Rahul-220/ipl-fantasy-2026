class User < ApplicationRecord
  has_many :match_entries, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
