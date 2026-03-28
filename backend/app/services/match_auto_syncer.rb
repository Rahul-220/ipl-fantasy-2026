class MatchAutoSyncer
  POLL_INTERVAL = 5.minutes  # Check status every 5 min
  SYNC_COOLDOWN = 30.minutes # Don't re-sync within 30 min of last sync

  def self.start!
    return if @running

    @running = true
    @synced_states = {}  # Track which state transitions we've already synced
    Rails.logger.info("[AutoSync] Starting auto-syncer (polling every #{POLL_INTERVAL / 60} min)")

    Thread.new do
      loop do
        begin
          check_and_sync
        rescue => e
          Rails.logger.error("[AutoSync] Error: #{e.message}\n#{e.backtrace.first(3).join("\n")}")
        end
        sleep POLL_INTERVAL
      end
    end
  end

  def self.check_and_sync
    # Step 1: Auto-update match statuses based on time
    Match.where(status: "upcoming").each do |m|
      m.auto_update_status!
    end

    # Step 2: Find matches that need monitoring (live or recently started)
    matches_to_monitor = Match.where(auto_sync: true, status: "live")

    return if matches_to_monitor.empty?

    Rails.logger.info("[AutoSync] Monitoring #{matches_to_monitor.count} live match(es)")

    matches_to_monitor.each do |match|
      next unless match.cricapi_match_id.present?

      # Check match status on Cricbuzz (lightweight scrape)
      status = CricbuzzScraper.fetch_match_status(match.cricapi_match_id)
      next unless status

      state = status[:match_state]
      state_key = "#{match.id}_#{state}"

      Rails.logger.info("[AutoSync] Match ##{match.match_number}: #{status[:status_text]} (#{state})")

      # Only sync at these two moments (as per user request):
      # 1. Innings break (first innings just ended)
      # 2. Match completed
      should_sync = false

      if state == "innings_break" && !@synced_states[state_key]
        should_sync = true
        @synced_states[state_key] = true
        Rails.logger.info("[AutoSync] 🔴 Innings break detected! Syncing scorecard...")
      end

      if state == "completed" && !@synced_states[state_key]
        should_sync = true
        @synced_states[state_key] = true
        Rails.logger.info("[AutoSync] 🏁 Match completed! Syncing final scorecard...")
      end

      if should_sync
        syncer = MatchSyncService.new(match)
        result = syncer.sync!
        Rails.logger.info("[AutoSync] Sync result: #{result[:success] ? 'OK' : 'FAILED'}")
        result[:log]&.each { |l| Rails.logger.info("[AutoSync] #{l}") }

        # Create a sync log record for the admin dashboard
        SyncLog.create!(
          match: match,
          status: result[:success] ? "success" : "failed",
          log_data: result[:log]&.join("\n"),
          synced_at: Time.current
        ) if defined?(SyncLog)
      end
    end
  end

  # Manual trigger for admin
  def self.sync_match!(match)
    syncer = MatchSyncService.new(match)
    syncer.sync!
  end
end
