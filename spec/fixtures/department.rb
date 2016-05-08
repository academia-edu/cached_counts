class Department < ActiveRecord::Base
  include CachedCounts

  belongs_to :university
  has_many :users

  caches_count_of :users,
    scope: -> { confirmed },
    if: :confirmed?

end
