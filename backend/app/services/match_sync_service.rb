class MatchSyncService
  attr_reader :match, :log

  def initialize(match)
    @match = match
    @log = []
  end

  # Main entry point — sync a match from CricAPI
  def sync!
    @log = []

    # Step 1: Ensure we have a CricAPI match ID
    unless match.cricapi_match_id.present?
      discover_cricapi_match_id!
      return { success: false, log: @log } unless match.cricapi_match_id.present?
    end

    # Step 2: Fetch scorecard from CricAPI
    api = CricApiService.new
    scorecard_data = api.match_scorecard(match.cricapi_match_id)

    unless scorecard_data && scorecard_data["status"] == "success"
      add_log("❌ Failed to fetch scorecard from CricAPI")
      return { success: false, log: @log }
    end

    data = scorecard_data["data"]
    add_log("✅ Fetched scorecard for: #{data['name']}")

    # Step 3: Check match status
    api_status = data["status"] || ""
    match_ended = api_status.downcase.include?("won") ||
                  api_status.downcase.include?("tied") ||
                  api_status.downcase.include?("no result") ||
                  api_status.downcase.include?("abandoned")
    add_log("📊 API Status: #{api_status}")

    # Step 4: Process scorecard innings
    innings = data["scorecard"] || []
    if innings.empty?
      add_log("⚠️ No scorecard data yet — match may not have started")
      match.update(last_synced_at: Time.current)
      return { success: true, log: @log, no_data: true }
    end

    # Step 5: Get all players from both teams in our match
    team1_players = IplPlayer.where(ipl_team_id: match.team1_id)
    team2_players = IplPlayer.where(ipl_team_id: match.team2_id)
    all_players = (team1_players + team2_players)
    player_name_map = build_player_name_map(all_players)

    # Step 6: Process each innings
    performance_data = {}

    innings.each do |inning|
      inning_name = inning["inning"] || "Unknown"
      add_log("📋 Processing: #{inning_name}")

      # Process batting
      (inning["batting"] || []).each do |bat|
        player = find_player(bat.dig("batsman", "name"), player_name_map)
        next unless player

        perf = performance_data[player.id] ||= default_performance(player.id)
        perf[:did_bat] = true
        perf[:runs_scored] = (bat["r"] || 0).to_i
        perf[:balls_faced] = (bat["b"] || 0).to_i
        perf[:fours] = (bat["4s"] || 0).to_i
        perf[:sixes] = (bat["6s"] || 0).to_i

        # Check for duck: out for 0 runs
        dismissal = bat["dismissal"] || ""
        is_out = dismissal.present? && !dismissal.downcase.include?("not out")
        perf[:is_duck] = is_out && perf[:runs_scored] == 0

        add_log("  🏏 #{player.name}: #{perf[:runs_scored]}(#{perf[:balls_faced]})")
      end

      # Process bowling
      (inning["bowling"] || []).each do |bowl|
        player = find_player(bowl.dig("bowler", "name"), player_name_map)
        next unless player

        perf = performance_data[player.id] ||= default_performance(player.id)
        perf[:overs_bowled] = (bowl["o"] || 0).to_f
        perf[:maidens] = (bowl["m"] || 0).to_i
        perf[:runs_conceded] = (bowl["r"] || 0).to_i
        perf[:wickets] = (bowl["w"] || 0).to_i

        add_log("  🎳 #{player.name}: #{perf[:wickets]}/#{perf[:runs_conceded]} (#{perf[:overs_bowled]}ov)")
      end

      # Process fielding (catches, stumpings, run outs)
      (inning["catching"] || []).each do |field|
        player = find_player(field.dig("catcher", "name"), player_name_map)
        next unless player

        perf = performance_data[player.id] ||= default_performance(player.id)
        perf[:catches] += (field["caught"] || 0).to_i
        perf[:stumpings] += (field["stumpiing"] || 0).to_i  # CricAPI typo: "stumpiing"
        run_outs = (field["runout"] || 0).to_i
        perf[:direct_run_outs] += run_outs  # API doesn't distinguish direct/indirect
      end
    end

    # Step 7: Also count LBW/bowled wickets for bowlers from batting dismissals
    innings.each do |inning|
      (inning["batting"] || []).each do |bat|
        dismissal_info = bat["dismissal-info"] || {}
        dismissal = bat["dismissal"] || ""

        # Check if LBW or bowled
        is_lbw = dismissal_info["lbw"] == true
        is_bowled = dismissal_info["bowled"] == true

        if is_lbw || is_bowled
          # Extract bowler name from dismissal string
          bowler_name = extract_bowler_from_dismissal(dismissal)
          if bowler_name
            player = find_player(bowler_name, player_name_map)
            if player
              perf = performance_data[player.id] ||= default_performance(player.id)
              perf[:lbw_bowled_count] += 1
            end
          end
        end
      end
    end

    # Step 8: Save performances to database
    saved_count = 0
    performance_data.each do |player_id, perf_data|
      record = PlayerMatchPerformance.find_or_initialize_by(
        match_id: match.id,
        ipl_player_id: player_id
      )
      record.assign_attributes(perf_data.except(:id))
      record.save!
      saved_count += 1
    end
    add_log("💾 Saved #{saved_count} player performances")

    # Step 9: Calculate fantasy points
    PointsCalculator.new(match).calculate_all!
    add_log("🔢 Fantasy points calculated")

    # Step 10: Update match status if ended
    if match_ended && match.status != "completed"
      match.update(status: "completed")
      add_log("🏁 Match marked as completed")
    elsif !match_ended && match.status == "upcoming"
      match.update(status: "live")
      add_log("🟢 Match marked as live")
    end

    match.update(last_synced_at: Time.current)
    add_log("✅ Sync complete!")

    { success: true, log: @log, performances: saved_count }
  end

  private

  def discover_cricapi_match_id!
    api = CricApiService.new
    unless api.api_key_present?
      add_log("❌ CRICAPI_KEY env variable not set")
      return
    end

    team1 = IplTeam.find(match.team1_id)
    team2 = IplTeam.find(match.team2_id)
    add_log("🔍 Searching CricAPI for #{team1.short_name} vs #{team2.short_name}...")

    api_match = api.find_ipl_match(team1.short_name, team2.short_name)
    if api_match
      match.update(cricapi_match_id: api_match["id"])
      add_log("✅ Found CricAPI match: #{api_match['name']} (ID: #{api_match['id']})")
    else
      add_log("❌ Could not find match in CricAPI current matches")
    end
  end

  def build_player_name_map(players)
    map = {}
    players.each do |player|
      # Store multiple keys for fuzzy matching
      full_name = player.name.downcase.strip
      map[full_name] = player

      # Also store by last name for partial matching
      parts = full_name.split(/\s+/)
      if parts.length > 1
        map[parts.last] = player unless map.key?(parts.last)
        # Also store "First Last" without middle names
        map["#{parts.first} #{parts.last}"] = player unless map.key?("#{parts.first} #{parts.last}")
      end
    end
    map
  end

  def find_player(api_name, player_name_map)
    return nil unless api_name.present?

    name = api_name.downcase.strip

    # 1. Exact match
    return player_name_map[name] if player_name_map[name]

    # 2. Check if API name ends with a player's full name or vice versa
    player_name_map.each do |key, player|
      return player if name.include?(key) || key.include?(name)
    end

    # 3. Last name match
    parts = name.split(/\s+/)
    if parts.length > 1
      last_name = parts.last
      return player_name_map[last_name] if player_name_map[last_name]
    end

    Rails.logger.warn("[MatchSync] Could not match player: #{api_name}")
    nil
  end

  def extract_bowler_from_dismissal(dismissal)
    return nil if dismissal.blank?

    # Patterns: "b Bowler Name", "lbw b Bowler Name", "c Fielder b Bowler Name"
    if match_data = dismissal.match(/\bb\s+(.+)$/i)
      match_data[1].strip
    end
  end

  def default_performance(player_id)
    {
      ipl_player_id: player_id,
      runs_scored: 0, balls_faced: 0, fours: 0, sixes: 0,
      is_duck: false, did_bat: false,
      overs_bowled: 0, maidens: 0, runs_conceded: 0, wickets: 0,
      lbw_bowled_count: 0,
      catches: 0, stumpings: 0,
      direct_run_outs: 0, indirect_run_outs: 0
    }
  end

  def add_log(msg)
    @log << msg
    Rails.logger.info("[MatchSync] #{msg}")
  end
end
