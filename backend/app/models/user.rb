class User < ApplicationRecord
  has_secure_password

  has_many :match_entries, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
