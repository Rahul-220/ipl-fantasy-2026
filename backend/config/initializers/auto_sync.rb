# Start the auto-syncer in production when server boots
# Only runs if CRICAPI_KEY is set
if defined?(Rails::Server) || defined?(Puma)
  Rails.application.config.after_initialize do
    if ENV["CRICAPI_KEY"].present?
      MatchAutoSyncer.start!
    else
      Rails.logger.info("[AutoSync] CRICAPI_KEY not set — auto-sync disabled")
    end
  end
end
