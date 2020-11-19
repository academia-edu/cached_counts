module CachedCounts
  class << self
    # Optional configuration: Set a proc which takes as arguments (1) the class
    # we are counting and (2) the block that runs the count query. The
    # `query_context` block must call the block that's passed as an argument.
    #
    # This is useful for replication, e.g.,
    #
    #     CachedCounts.query_context = proc do |klass, &run_query|
    #       role = klass == User ? :reading : :writing
    #       ActiveRecord::Base.connected_to(role: role) do
    #         run_query.call
    #       end
    #     end
    attr_writer :query_context

    def query_context
      @query_context ||= proc { |_klass, &block| block.call }
    end
  end
end
