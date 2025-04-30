source 'https://rubygems.org'

# Declare your gem's dependencies in cached_counts.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

ar_version = ENV["ACTIVERECORD_VERSION"] || "default"
case ar_version
when "default"
  # Allow the gemspec to specify
else
  gem "activerecord", "~> #{ar_version}", group: [:development, :test]
end

