class User < ActiveRecord::Base
  include CachedCounts

  belongs_to :department

  has_many :follower_joins,
    class_name: 'Following',
    foreign_key: :followee_id,
    dependent: :destroy
  has_many :followers, through: :follower_joins, class_name: 'User'

  has_many :followee_joins,
    class_name: 'Following',
    foreign_key: :follower_id,
    dependent: :destroy
  has_many :followees, through: :followee_joins, class_name: 'User'

  scope :confirmed, -> { where(confirmed: true) }
  scope :unconfirmed, -> { where(confirmed: [nil, false]) }

  caches_count_where :confirmed, if: :confirmed?
  caches_count_where :unconfirmed, if: ->{ !confirmed? }, alias: :spammer

  caches_count_of :follower_joins, alias: :followers

end
