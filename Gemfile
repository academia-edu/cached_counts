source 'https://rubygems.org'

# Declare your gem's dependencies in cached_counts.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

ar_version = ENV["ACTIVERECORD_VERSION"] || "default"
case ar_version
when "master"
  gem "activerecord", {github: "rails/rails"}, group: [:development, :test]
when "default"
  # Allow the gemspec to specify
else
  gem "activerecord", "~> #{ar_version}", group: [:development, :test]
end

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

gem 'pry', group: [:development, :test]
