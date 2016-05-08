$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "cached_counts/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "cached_counts"
  s.version     = CachedCounts::VERSION
  s.authors     = ["David Judd"]
  s.email       = ["david@academia.edu"]
  s.homepage    = "https://github.com/academia-edu/cached_counts"
  s.summary     = "A replacement for Rails' counter caches using memcached (via Dalli)"
  s.description = "A replacement for Rails' counter caches using memcached increment & decrement operations, implemented via after_commit hooks and the Dalli gem"
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rails", ">= 4.0"
  s.add_dependency "dalli"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "test_after_commit"
  s.add_development_dependency "rake"
end
