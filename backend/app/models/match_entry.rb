class MatchEntry < ApplicationRecord
  belongs_to :user
  belongs_to :match
  belongs_to :captain, class_name: "IplPlayer", optional: true
  belongs_to :vice_captain, class_name: "IplPlayer", optional: true
  has_many :team_selections, dependent: :destroy
  has_many :selected_players, through: :team_selections, source: :ipl_player

  validates :user_id, uniqueness: { scope: :match_id, message: "already has an entry for this match" }
  validate :match_not_full, on: :create
  validate :captain_in_team, if: :captain_id
  validate :vice_captain_in_team, if: :vice_captain_id

  private

  def match_not_full
    if match&.match_entries&.count.to_i >= 5
      errors.add(:match, "already has 5 entries (maximum)")
    end
  end

  def captain_in_team
    unless team_selections.map(&:ipl_player_id).include?(captain_id)
      errors.add(:captain, "must be one of your selected players")
    end
  end

  def vice_captain_in_team
    unless team_selections.map(&:ipl_player_id).include?(vice_captain_id)
      errors.add(:vice_captain, "must be one of your selected players")
    end
  end
end
