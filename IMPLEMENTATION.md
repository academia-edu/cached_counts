There are two ways we update a cached count:
  * When we try to fetch the count, if it isn't already cached, we calculate it from the database and cache the result.
  * When a record is created/deleted/updated, an after_commit hook updates the count using Memcached's `incr` and `decr` commands.

It's possible for the count to get out of sync with what's in the database. At Academia.edu, we use this method of counting only when we're okay with some inaccuracy:
  * We create models much more often than we destroy them. Thus, the count is roughly monotonic over time. This means that only large values are likely to get out of sync, for two reasons:
    * Small values are only a few unreliable operations away from a database recalculation, whereas large values are many unreliable operations away.
    * Small values have expiry-resetting operations (i.e., `incr`/`decr`) applied to them infrequently, so they expire and are recalculated often.
  * It's often okay for big values to be slightly off:
    * In paginated lists where the total item count is displayed to the user.
    * In calculations that depend on only the order of magnitude of the count, not the exact value.
