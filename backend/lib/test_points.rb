# Test points calculation for Match 1 (RCB vs SRH)
# Run: docker compose exec backend rails runner lib/test_points.rb

match = Match.find_by(match_number: 1)
abort "Match 1 not found!" unless match

puts "=== Testing Points for #{match.team1.short_name} vs #{match.team2.short_name} ==="
puts ""

# Get all users
users = User.all
abort "Need at least 2 users!" if users.count < 2

# Get players from both teams
team1_players = match.team1.ipl_players
team2_players = match.team2.ipl_players

puts "#{match.team1.short_name}: #{team1_players.count} players"
puts "#{match.team2.short_name}: #{team2_players.count} players"
puts ""

# Clear any existing entries for this match
match.match_entries.destroy_all
PlayerMatchPerformance.where(match: match).destroy_all

# Each user picks 11 players (6 from team1, 5 from team2 — mixing it up)
users.each_with_index do |user, idx|
  t1_picks = team1_players.order(:id).offset(idx).limit(6).to_a
  t2_picks = team2_players.order(:id).offset(idx).limit(5).to_a
  picks = t1_picks + t2_picks

  entry = match.match_entries.create!(user: user)
  picks.each { |p| entry.team_selections.create!(ipl_player_id: p.id) }
  entry.update!(captain_id: picks[0].id, vice_captain_id: picks[1].id)

  puts "#{user.name}'s team (C: #{picks[0].name}, VC: #{picks[1].name}):"
  picks.each { |p| puts "  - #{p.name} (#{p.role})" }
  puts ""
end

# Simulate player performances for ALL players in the match
puts "=== Simulating Performances ==="
all_players = team1_players + team2_players

all_players.each do |player|
  perf = PlayerMatchPerformance.find_or_initialize_by(match: match, ipl_player: player)

  # Give different stats based on role for realistic-ish results
  case player.role
  when "batsman"
    perf.assign_attributes(
      did_bat: true, runs_scored: rand(10..75), balls_faced: rand(15..45),
      fours: rand(1..6), sixes: rand(0..3), is_duck: false,
      overs_bowled: 0, wickets: 0, maidens: 0, runs_conceded: 0,
      catches: rand(0..1), stumpings: 0, direct_run_outs: 0, indirect_run_outs: 0
    )
  when "bowler"
    perf.assign_attributes(
      did_bat: [true, false].sample, runs_scored: rand(0..20), balls_faced: rand(2..15),
      fours: rand(0..2), sixes: rand(0..1), is_duck: (rand(3) == 0),
      overs_bowled: rand(2..4), wickets: rand(0..3), maidens: rand(0..1),
      runs_conceded: rand(15..40), lbw_bowled_count: rand(0..1),
      catches: rand(0..1), stumpings: 0, direct_run_outs: 0, indirect_run_outs: 0
    )
  when "all_rounder"
    perf.assign_attributes(
      did_bat: true, runs_scored: rand(15..50), balls_faced: rand(10..35),
      fours: rand(1..4), sixes: rand(0..2), is_duck: false,
      overs_bowled: rand(2..4), wickets: rand(0..2), maidens: rand(0..1),
      runs_conceded: rand(20..35), lbw_bowled_count: rand(0..1),
      catches: rand(0..2), stumpings: 0, direct_run_outs: rand(0..1), indirect_run_outs: 0
    )
  when "wicket_keeper"
    perf.assign_attributes(
      did_bat: true, runs_scored: rand(10..60), balls_faced: rand(12..40),
      fours: rand(1..5), sixes: rand(0..3), is_duck: false,
      overs_bowled: 0, wickets: 0, maidens: 0, runs_conceded: 0,
      catches: rand(1..3), stumpings: rand(0..1), direct_run_outs: 0, indirect_run_outs: 0
    )
  end

  perf.save!
  puts "  #{player.name.ljust(25)} #{player.role.ljust(15)} => #{perf.fantasy_points.to_f.round(1)} pts"
end

# Set match to completed
match.update!(status: "completed")

# Calculate entry totals (same logic as the controller)
puts ""
puts "=== Calculating Entry Totals ==="
match.match_entries.includes(:team_selections, :captain, :vice_captain).each do |entry|
  total = 0.0
  entry.team_selections.each do |selection|
    perf = PlayerMatchPerformance.find_by(match_id: match.id, ipl_player_id: selection.ipl_player_id)
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

# Print leaderboard
puts ""
puts "=== 🏆 MATCH 1 LEADERBOARD ==="
match.match_entries.includes(:user).order(total_points: :desc).each_with_index do |entry, idx|
  medal = ["🥇", "🥈", "🥉"][idx] || "  "
  puts "#{medal} #{entry.user.name.ljust(12)} #{entry.total_points.round(1)} pts"
end
puts ""
puts "Done! Check the app at http://localhost:5173/matches/#{match.id}"
