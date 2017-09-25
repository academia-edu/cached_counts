if defined?(Rails)
  ActiveSupport.on_load :cached_counts do
    unless Rails.cache.respond_to?(:dalli) || (defined?(Dalli::Client) && Rails.cache.instance_variable_get(:@data).is_a?(Dalli::Client))
      raise "CachedCounts depends on Dalli!"
    end
  end
end
