class IplPlayer < ApplicationRecord
  belongs_to :ipl_team
  has_many :team_selections, dependent: :destroy
  has_many :player_match_performances, dependent: :destroy

  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: %w[batsman bowler all_rounder wicket_keeper] }

  scope :by_team, ->(team_id) { where(ipl_team_id: team_id) }
end
