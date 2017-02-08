if defined?(Rails)
  ActiveSupport.on_load :cached_counts do
    unless Rails.cache.respond_to?(:dalli) || Rails.cache.respond_to?(:pool)
      raise "CachedCounts depends on Dalli or Readthis!"
    end
  end
end
