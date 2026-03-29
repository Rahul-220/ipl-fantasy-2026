class Match < ApplicationRecord
  belongs_to :team1, class_name: "IplTeam"
  belongs_to :team2, class_name: "IplTeam"
  has_many :match_entries, dependent: :destroy
  has_many :player_match_performances, dependent: :destroy

  validates :match_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[upcoming live completed] }

  scope :upcoming, -> { where(status: "upcoming").order(:match_date) }
  scope :completed, -> { where(status: "completed").order(match_date: :desc) }
  scope :ordered, -> { order(:match_date) }

  # Time-based locking: returns true if match time has passed OR status is not upcoming
  def started?
    status != "upcoming" || (match_date.present? && Time.current >= match_date)
  end

  # Auto-update status based on current time (only writes if needed)
  def auto_update_status!
    return unless match_date.present?

    if status == "upcoming" && Time.current >= match_date
      update_column(:status, "live")  # Faster than update! — skips callbacks/validations
    end
  end

  def players
    IplPlayer.where(ipl_team_id: [team1_id, team2_id])
  end

  def full?
    match_entries.count >= 5
  end

  def leaderboard
    match_entries.includes(:user).order(total_points: :desc)
  end
end
