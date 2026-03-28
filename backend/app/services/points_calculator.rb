class PointsCalculator
  def initialize(match)
    @match = match
  end

  def calculate_all!
    @match.match_entries.includes(:team_selections, :captain, :vice_captain).each do |entry|
      total = 0.0

      entry.team_selections.each do |selection|
        perf = PlayerMatchPerformance.find_by(match_id: @match.id, ipl_player_id: selection.ipl_player_id)
        next unless perf

        points = perf.fantasy_points.to_f

        if entry.captain_id == selection.ipl_player_id
          points *= 2.0
        elsif entry.vice_captain_id == selection.ipl_player_id
          points *= 1.5
        end

        total += points
      end

      entry.update!(total_points: total)
    end
  end
end
