module CachedCounts
  class << self
    # Optional configuration: set a proc which takes the class we are counting
    # and returns a connection. Useful with replication, e.g. with Octopus:
    #
    # `CachedCounts.connection_for = proc { |klass| klass.using(:read_slave).connection }`
    attr_writer :connection_for

    def connection_for(counted_class)
      @connection_for ||= proc { |klass| klass.connection }
      @connection_for[counted_class]
    end
  end
end
