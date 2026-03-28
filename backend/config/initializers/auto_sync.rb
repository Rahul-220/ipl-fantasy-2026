# Start the auto-syncer when server boots
# No API key needed — uses Cricbuzz scraping
if defined?(Rails::Server) || defined?(Puma)
  Rails.application.config.after_initialize do
    MatchAutoSyncer.start!
    Rails.logger.info("[AutoSync] Auto-syncer started (Cricbuzz scraping)")
  end
end
