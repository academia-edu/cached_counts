class Following < ActiveRecord::Base
  include CachedCounts

  belongs_to :followee, class_name: 'User'
  belongs_to :follower, class_name: 'User'

end
