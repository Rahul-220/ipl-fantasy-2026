class MatchSyncService
  attr_reader :match, :log

  def initialize(match)
    @match = match
    @log = []
  end

  # Main entry point — sync a match from Cricbuzz scorecard
  def sync!
    @log = []

    cricbuzz_id = match.cricapi_match_id
    unless cricbuzz_id.present?
      add_log("❌ No Cricbuzz match ID set — trying auto-discover...")
      discover_cricbuzz_id!
      cricbuzz_id = match.reload.cricapi_match_id
      return { success: false, log: @log } unless cricbuzz_id.present?
    end

    # Fetch full scorecard from Cricbuzz embedded JSON
    add_log("📡 Fetching scorecard from Cricbuzz (ID: #{cricbuzz_id})...")
    scorecard_data = CricbuzzScraper.fetch_scorecard(cricbuzz_id)

    unless scorecard_data && scorecard_data["scoreCard"].present?
      add_log("❌ No scorecard data found — match may not have started")
      match.update(last_synced_at: Time.current)
      return { success: false, log: @log }
    end

    innings_list = scorecard_data["scoreCard"]
    add_log("✅ Got #{innings_list.size} innings of scorecard data")

    # Get all players from both teams
    all_players = IplPlayer.where(ipl_team_id: [match.team1_id, match.team2_id])
    player_name_map = build_player_name_map(all_players)

    # Process each innings
    performance_data = {}

    innings_list.each_with_index do |inning, idx|
      add_log("📋 Processing innings #{idx + 1}...")

      # Process batting
      bat_data = inning.dig("batTeamDetails", "batsmenData") || {}
      bat_data.each do |_key, bat|
        player = find_player(bat["batName"], player_name_map)
        next unless player

        perf = performance_data[player.id] ||= default_performance(player.id)
        perf[:did_bat] = true
        perf[:runs_scored] = bat["runs"].to_i
        perf[:balls_faced] = bat["balls"].to_i
        perf[:fours] = bat["fours"].to_i
        perf[:sixes] = bat["sixes"].to_i

        # Duck check: out for 0 runs
        is_out = bat["outDesc"].present? && !bat["outDesc"].downcase.include?("not out") && bat["wicketCode"].present?
        perf[:is_duck] = is_out && perf[:runs_scored] == 0

        # Track LBW/Bowled for bonus points
        wkt_code = (bat["wicketCode"] || "").upcase
        if %w[LBW BOWLED].include?(wkt_code) && bat["bowlerId"].present?
          bowler_id_key = "bowler_#{bat['bowlerId']}"
          performance_data[bowler_id_key] ||= 0
          performance_data[bowler_id_key] += 1
        end

        add_log("  🏏 #{player.name}: #{perf[:runs_scored]}(#{perf[:balls_faced]}) #{bat['outDesc']}")
      end

      # Process bowling
      bowl_data = inning.dig("bowlTeamDetails", "bowlersData") || {}
      bowl_data.each do |_key, bowl|
        player = find_player(bowl["bowlName"], player_name_map)
        next unless player

        perf = performance_data[player.id] ||= default_performance(player.id)
        perf[:overs_bowled] = bowl["overs"].to_f
        perf[:maidens] = bowl["maidens"].to_i
        perf[:runs_conceded] = bowl["runs"].to_i
        perf[:wickets] = bowl["wickets"].to_i

        add_log("  🎳 #{player.name}: #{perf[:wickets]}/#{perf[:runs_conceded]} (#{perf[:overs_bowled]}ov)")
      end

      # Process fielding (catches from batting dismissals)
      bat_data.each do |_key, bat|
        next unless bat["wicketCode"].present?
        wkt_code = (bat["wicketCode"] || "").upcase

        # Catches
        if %w[CAUGHT CAUGHT_BEHIND].include?(wkt_code) && bat["fielderId1"].present? && bat["fielderId1"] != 0
          fielder = find_player_by_cricbuzz_id(bat["fielderId1"], all_players, player_name_map)
          if fielder
            perf = performance_data[fielder.id] ||= default_performance(fielder.id)
            perf[:catches] += 1
          end
        end

        # Stumpings
        if wkt_code == "STUMPED" && bat["fielderId1"].present? && bat["fielderId1"] != 0
          fielder = find_player_by_cricbuzz_id(bat["fielderId1"], all_players, player_name_map)
          if fielder
            perf = performance_data[fielder.id] ||= default_performance(fielder.id)
            perf[:stumpings] += 1
          end
        end

        # Run outs
        if wkt_code == "RUN_OUT" && bat["fielderId1"].present? && bat["fielderId1"] != 0
          fielder = find_player_by_cricbuzz_id(bat["fielderId1"], all_players, player_name_map)
          if fielder
            perf = performance_data[fielder.id] ||= default_performance(fielder.id)
            perf[:direct_run_outs] += 1
          end
        end

        # LBW/Bowled bonus for bowler
        if %w[LBW BOWLED].include?(wkt_code) && bat["bowlerId"].present?
          bowler = find_player_by_cricbuzz_id(bat["bowlerId"], all_players, player_name_map)
          if bowler
            perf = performance_data[bowler.id] ||= default_performance(bowler.id)
            perf[:lbw_bowled_count] += 1
          end
        end
      end
    end

    # Remove non-player keys (bowler tracking)
    performance_data.reject! { |k, _| k.is_a?(String) }

    # Save performances to database
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

    # Calculate fantasy points
    PointsCalculator.new(match).calculate_all!
    add_log("🔢 Fantasy points calculated")

    # Check match status from Cricbuzz
    status_info = CricbuzzScraper.fetch_match_status(cricbuzz_id)
    if status_info
      case status_info[:match_state]
      when "completed"
        match.update!(status: "completed") unless match.status == "completed"
        add_log("🏁 Match marked as completed: #{status_info[:status_text]}")
      when "innings_break"
        match.update!(status: "live") unless match.status == "live"
        add_log("⏸️ Innings break: #{status_info[:status_text]}")
      when "live"
        match.update!(status: "live") unless match.status == "live"
        add_log("🟢 Match is live")
      end
    end

    match.update!(last_synced_at: Time.current)
    add_log("✅ Sync complete!")

    { success: true, log: @log, performances: saved_count }
  end

  private

  def discover_cricbuzz_id!
    discovered = CricbuzzScraper.auto_map_matches!
    discovered.each { |msg| add_log(msg) }
  end

  def build_player_name_map(players)
    map = {}
    players.each do |player|
      full_name = player.name.downcase.strip
      map[full_name] = player

      parts = full_name.split(/\s+/)
      if parts.length > 1
        map[parts.last] = player unless map.key?(parts.last)
        map["#{parts.first} #{parts.last}"] = player unless map.key?("#{parts.first} #{parts.last}")
      end
    end
    map
  end

  def find_player(api_name, player_name_map)
    return nil unless api_name.present?
    name = api_name.downcase.strip

    return player_name_map[name] if player_name_map[name]

    player_name_map.each do |key, player|
      return player if name.include?(key) || key.include?(name)
    end

    parts = name.split(/\s+/)
    if parts.length > 1
      return player_name_map[parts.last] if player_name_map[parts.last]
    end

    Rails.logger.warn("[MatchSync] Could not match player: #{api_name}")
    nil
  end

  def find_player_by_cricbuzz_id(cricbuzz_player_id, all_players, player_name_map)
    # Cricbuzz uses numeric player IDs — we don't store these, so we can't match directly
    # This is a limitation; fielding stats may be incomplete
    # In future, we could add a cricbuzz_id field to IplPlayer
    nil
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
