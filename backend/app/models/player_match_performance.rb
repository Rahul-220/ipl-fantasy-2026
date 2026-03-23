class PlayerMatchPerformance < ApplicationRecord
  belongs_to :match
  belongs_to :ipl_player

  validates :ipl_player_id, uniqueness: { scope: :match_id }

  before_save :calculate_fantasy_points

  private

  def calculate_fantasy_points
    points = 0.0

    # === BATTING ===
    points += runs_scored                        # +1 per run
    points += fours                              # +1 bonus per boundary
    points += (sixes * 2)                        # +2 bonus per six
    points += 4 if runs_scored >= 30             # 30 run bonus
    points += 8 if runs_scored >= 50             # half-century bonus
    points += 16 if runs_scored >= 100           # century bonus

    # Duck: -2 for batsman, WK, all-rounder (not bowlers)
    if is_duck && did_bat && %w[batsman wicket_keeper all_rounder].include?(ipl_player&.role)
      points -= 2
    end

    # === BOWLING ===
    points += (wickets * 25)                     # +25 per wicket
    points += (lbw_bowled_count * 8)             # +8 per LBW/Bowled
    points += 4 if wickets >= 3                  # 3-wicket bonus
    points += 8 if wickets >= 4                  # 4-wicket bonus (stacks with 3W)
    points += 16 if wickets >= 5                 # 5-wicket bonus (stacks)
    points += (maidens * 12)                     # +12 per maiden

    # === FIELDING ===
    points += (catches * 8)                      # +8 per catch
    points += (stumpings * 12)                   # +12 per stumping
    points += (direct_run_outs * 12)             # +12 per direct run out
    points += (indirect_run_outs * 6)            # +6 per indirect run out

    self.fantasy_points = points
  end
end
