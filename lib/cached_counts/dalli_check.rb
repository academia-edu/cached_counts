if defined?(Rails)
  ActiveSupport.on_load :cached_counts do
    raise "CachedCounts depends on Dalli!" unless Rails.cache.respond_to?(:dalli)
  end
end
