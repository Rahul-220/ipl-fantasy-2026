# Auto-syncer disabled — using manual sync via admin UI instead.
# Render free tier only has one process; background threads
# compete for resources and cause API slowness.
#
# To re-enable in future (paid Render or always-on server):
#   if defined?(Rails::Server) || defined?(Puma)
#     Rails.application.config.after_initialize do
#       MatchAutoSyncer.start!
#     end
#   end
