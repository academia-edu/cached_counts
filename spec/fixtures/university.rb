class University < ActiveRecord::Base
  include CachedCounts

  has_many :departments
  has_many :users, through: :departments

  caches_count_of :users,
    scope: -> { where(confirmed: true) },
    if: ->{ confirmed? }

end
