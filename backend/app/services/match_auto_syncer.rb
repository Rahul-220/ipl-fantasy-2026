class MatchAutoSyncer
  SYNC_INTERVAL = 5.minutes

  def self.start!
    return unless ENV["CRICAPI_KEY"].present?
    return if @running

    @running = true
    Rails.logger.info("[AutoSync] Starting match auto-syncer (every #{SYNC_INTERVAL / 60} minutes)")

    Thread.new do
      loop do
        begin
          sync_live_matches
        rescue => e
          Rails.logger.error("[AutoSync] Error: #{e.message}")
        end
        sleep SYNC_INTERVAL
      end
    end
  end

  def self.sync_live_matches
    # Find matches that have auto_sync enabled and are live or upcoming (near start time)
    matches_to_sync = Match.where(auto_sync: true)
                           .where(status: ["live", "upcoming"])

    return if matches_to_sync.empty?

    Rails.logger.info("[AutoSync] Syncing #{matches_to_sync.count} match(es)...")

    matches_to_sync.each do |match|
      # Skip upcoming matches that haven't started yet (more than 30 min away)
      if match.status == "upcoming" && match.match_date && match.match_date > 30.minutes.from_now
        next
      end

      syncer = MatchSyncService.new(match)
      result = syncer.sync!
      Rails.logger.info("[AutoSync] Match ##{match.match_number}: #{result[:success] ? 'OK' : 'FAILED'}")
    end
  end
end
