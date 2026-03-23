class IplTeam < ApplicationRecord
  has_many :ipl_players, dependent: :destroy
  has_many :home_matches, class_name: "Match", foreign_key: :team1_id
  has_many :away_matches, class_name: "Match", foreign_key: :team2_id

  validates :name, presence: true
  validates :short_name, presence: true

  def players_count
    ipl_players.count
  end
end
