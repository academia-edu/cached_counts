module CachedCounts
  class Railtie < Rails::Railtie
    config.after_initialize do
      ActiveSupport.run_load_hooks :cached_counts
    end
  end
end
