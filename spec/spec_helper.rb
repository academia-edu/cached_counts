require 'rubygems'
require 'bundler/setup'
require 'pry'
require 'active_record'
require 'rails'
require 'active_support/cache/mem_cache_store'
require 'cached_counts'

ActiveRecord::Base.configurations = YAML::load_file('spec/database.yml')
ActiveRecord::Base.establish_connection(:cached_counts_test)

if ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks)
  ActiveRecord::Base.raise_in_transactional_callbacks = true
end

Rails.cache = ActiveSupport::Cache::MemCacheStore.new("localhost")

RSpec.configure do |config|
  config.before(:each) do
    Rails.cache.clear
  end
end

# After the DB connection is setup
require_relative './fixtures.rb'
require 'database_cleaner'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

ActiveSupport.run_load_hooks :cached_counts
