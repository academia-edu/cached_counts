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

  if Gem::Version.new(ar_version) >= Gem::Version.new("8.0")
    gem "sqlite3", "~> 2.6"
  else
    gem "sqlite3", "~> 1.7"
  end
end
