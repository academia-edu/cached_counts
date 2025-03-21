require 'cached_counts/logger'
require 'cached_counts/query_context'

module CachedCounts
  extend ActiveSupport::Concern

  module ClassMethods
    # Cache the count for a scope in memcached.
    #
    # e.g.
    #   User.caches_count_where :confirmed
    #   > User.confirmed_count # User.confirmed.count, but cached
    #
    # Automatically adds after_commit hooks which increment/decrement the value
    # in memcached when needed. Queries the db on cache miss.
    #
    # @param [String] attribute_name
    #
    # @param [Hash] options
    #
    # @option options [String] :scope
    #   Name of the scope to count. Defaults to the +attribute_name+
    #   (the required argument to +caches_count_where+).
    #
    # @option options [String, Array<String>] :alias
    #   Alias(es) for the count attribute.
    #   e.g.
    #     caches_count_where :confirmed, alias: 'sitemap'
    #     > User.sitemap_count
    #
    # @option options [Integer] :expires_in
    #   Expiry for the cached value.
    #
    # @option options [Proc] :if
    #   proc passed through to the after_commit hooks;
    #   decides whether an object counts towards the association total.
    #
    # @option options [Integer, #to_s] :version
    #   Cache version - bump if you change the definition of a count.
    #
    # @option options [Proc] :race_condition_fallback
    #   Fallback to the result of this proc if the cache is empty, while
    #   loading the actual value from the db. Works similarly to
    #   +race_condition_ttl+ but for empty caches rather than expired values.
    #   Meant to prevent a thundering-herd scenario, if for example a
    #   memcached instance goes away. Can be nil; defaults to using a value
    #   grabbed from the cache or DB at startup.
    #
    def caches_count_where(attribute_name, options = {})
      # Delay actual run to work around circular dependencies
      klass = self
      ActiveSupport.on_load :cached_counts do
        klass.send :caches_count_where!, attribute_name, options
      end
    end

    # Cache the count for an association in memcached.
    #
    # e.g.
    #   User.caches_count_of :friends
    #   > User.first.friends_count # Users.first.friends.count, but cached
    #
    # Automatically adds after_commit hooks to the associated class which
    # increment/decrement the value in memcached when needed. Queries the db
    # on cache miss.
    #
    # @param [String] attribute_name
    #
    # @param [Hash] options
    #
    # @option options [Symbol] :association
    #   Name of the association to count. Defaults to the +attribute_name+
    #   (the required argument to +caches_count_of+).
    #
    # @option options [String, Array<String>] :alias
    #   Alias(es) for the count attribute. Useful with join tables.
    #   e.g.
    #     caches_count_of :user_departments, alias: 'users'
    #     > Department.first.users_count
    #
    # @option options [Integer] :expires_in
    #   Expiry for the cached value.
    #
    # @option options [Proc] :if
    #   proc passed through to the after_commit hooks on the counted class;
    #   decides whether an object counts towards the association total.
    #
    # @option options [Proc] :scope
    #   proc used like an ActiveRecord scope on the counted class on cache misses.
    #
    # @option options [Integer, #to_s] :version
    #   Cache version - bump if you change the definition of a count.
    #
    def caches_count_of(attribute_name, options = {})
      # Delay actual run to work around circular dependencies
      klass = self
      ActiveSupport.on_load :cached_counts do
        klass.send :caches_count_of!, attribute_name, options
      end
    end

    # @private
    def scope_count_key(attribute_name, version = 1)
      "#{name}:#{attribute_name}_count:#{version}"
    end

    # @private
    def association_count_key(counter_id, attribute_name, version = 1)
      "#{name}:#{counter_id}:#{attribute_name}_count:#{version}" unless counter_id.nil?
    end

    protected

    def caches_count_where!(attribute_name, options)
      scope_name = options.fetch :scope, attribute_name
      relation = send(scope_name) if respond_to?(scope_name)
      raise "#{self} does not have a scope named #{scope_name}" unless relation.is_a?(ActiveRecord::Relation)

      define_scope_count_attribute attribute_name, relation, options
      add_scope_counting_hooks attribute_name, options
    end

    def caches_count_of!(attribute_name, options)
      association_name = options.fetch :association, attribute_name
      association = reflect_on_association(association_name.to_sym)
      raise "#{self} does not have an association named #{association_name}" unless association

      define_association_count_attribute attribute_name, association, options
      add_association_counting_hooks attribute_name, association, options
    end

    def define_scope_count_attribute(attribute_name, relation, options)
      options = options.dup

      version = options.fetch :version, 1
      key = scope_count_key(attribute_name, version)

      unless options.has_key?(:race_condition_fallback)
        options[:race_condition_fallback] = default_race_condition_fallback_proc(
          key,
          relation,
          options
        )
      end

      [attribute_name, *Array(options[:alias])].each do |attr_name|
        add_count_attribute_methods(
          attr_name,
          -> { key },
          -> { relation },
          :define_singleton_method,
          self,
          options
        )
      end
    end

    def default_race_condition_fallback_proc(key, relation, options)
      fallback = Rails.cache.read(key, raw: true)
      fallback = fallback.value if fallback.is_a?(ActiveSupport::Cache::Entry)

      -> { fallback }
    end

    def define_association_count_attribute(attribute_name, association, options)
      options = options.dup

      version = options.fetch :version, 1
      key_getter = -> { self.class.association_count_key(id, attribute_name, version) }
      relation_getter = generate_association_relation_getter(association, options)

      [attribute_name, *Array(options[:alias])].each do |attr_name|
        define_singleton_method "#{attr_name}_count_key" do |id|
          association_count_key(id, attribute_name, version)
        end

        # Try to fetch values for ids from the cache. If it's a miss return the default value
        define_singleton_method "try_#{attr_name}_counts_for" do |ids, default=nil|
          raw_result = Rails.cache.read_multi(*ids.map{|id| association_count_key(id, attribute_name, version)}, raw: true)

          result = {}
          ids.each do |id|
            result[id] = raw_result[association_count_key(id, attribute_name, version)]&.to_i || default
          end

          result
        end

        define_singleton_method "#{attr_name}_count_for" do |id|
          new({id: id}, without_protection: true).send("#{attr_name}_count")
        end

        add_count_attribute_methods(
          attr_name,
          key_getter,
          relation_getter,
          :define_method,
          association.klass,
          options
        )
      end
    end

    def add_scope_counting_hooks(attribute_name, options)
      version = options.fetch :version, 1
      key = scope_count_key(attribute_name, version)

      add_counting_hooks(
        attribute_name,
        -> { key },
        self,
        options
      )
    end

    def add_association_counting_hooks(attribute_name, association, options)
      key_getter = generate_association_counting_hook_key_getter association, attribute_name, options

      add_counting_hooks(
        "#{name.demodulize.underscore}_#{attribute_name}",
        key_getter,
        association.klass,
        options
      )
    end

    def add_count_attribute_methods(attribute_name, key_getter, relation_getter, define_with, counted_class, options)
      expires_in = options.fetch :expires_in, 1.week
      race_condition_fallback = options.fetch :race_condition_fallback, nil

      key_method = "#{attribute_name}_count_key"

      send define_with, key_method, &key_getter

      send define_with, "#{attribute_name}_count" do
        val = Rails.cache.fetch(
          send(key_method),
          expires_in: expires_in,
          race_condition_ttl: 30.seconds,
          raw: true # Necessary for incrementing to work correctly
        ) do
          if race_condition_fallback
            # Ensure that other reads find something in the cache, but
            # continue calculating here because the default is likely inaccurate.
            fallback_value = instance_exec &race_condition_fallback

            if fallback_value
              CachedCounts.logger.warn "Setting #{fallback_value} as race_condition_fallback for #{send(key_method)}"
              Rails.cache.write(
                send(key_method),
                fallback_value.to_i,
                expires_in: 30.seconds,
                raw: true
              )
            end
          end

          relation = instance_exec(&relation_getter)
          relation = relation.reorder('')
          relation.select_values = ['count(*)']

          CachedCounts.query_context.call(counted_class) do
            counted_class.connection.select_value(relation.to_sql).to_i
          end
        end

        if val.is_a?(ActiveSupport::Cache::Entry)
          val.value.to_i
        else
          val.to_i
        end
      end

      send define_with, "#{attribute_name}_count=" do |value|
        Rails.cache.write(
          send(key_method),
          value.to_i,
          expires_in: expires_in,
          raw: true
        )
      end

      send define_with, "expire_#{attribute_name}_count" do
        Rails.cache.delete send(key_method)
      end
    end

    def add_counting_hooks(attribute_name, key_getter, counted_class, options)
      increment_hook = "increment_#{attribute_name}_count".to_sym
      counted_class.send :define_method, increment_hook do
        if (key = instance_exec &key_getter)
          Rails.cache.increment(
            key,
            1,
            initial: nil # Increment only if the key already exists
          )
        end
      end

      decrement_hook = "decrement_#{attribute_name}_count".to_sym
      counted_class.send :define_method, decrement_hook do
        if (key = instance_exec &key_getter)
          Rails.cache.decrement(
            key,
            1,
            initial: nil # Decrement only if the key already exists
          )
        end
      end

      counted_class.after_commit increment_hook, options.slice(:if).merge(on: :create)

      # This is ridiculous, but I can't find a better way to test for it
      need_without_protection = instance_method(:assign_attributes).arity != 1

      if (if_proc = options[:if])
        if if_proc.is_a?(Symbol)
          if_proc = ->{ send(options[:if]) }
        end

        recorded_eligibility_var = "@_was_eligible_for_#{attribute_name}_count"
        counted_class.before_destroy do
          instance_variable_set recorded_eligibility_var, !!instance_exec(&if_proc)
          true
        end
        counted_class.after_commit on: :destroy do
          if instance_variable_get(recorded_eligibility_var)
            send(decrement_hook)
          end
        end

        counted_class.after_commit on: :update do
          # There is no before-hook which will reliably have access to the
          # previous version of the object, so we need to simulate it.
          previous_values = previous_changes.each_with_object({}) do |(key,vals), memo|
            memo[key] = vals.first
          end

          old_version = dup
          if need_without_protection
            old_version.assign_attributes previous_values, without_protection: true
          else
            old_version.assign_attributes previous_values
          end

          was = !!old_version.instance_exec(&if_proc)
          is = !!instance_exec(&if_proc)
          if was != is
            if is
              send(increment_hook)
            else
              send(decrement_hook)
            end
          end
        end
      else
        counted_class.after_commit decrement_hook, on: :destroy
      end
    end

    def generate_association_counting_hook_key_getter(association, attribute_name, options)
      version = options.fetch :version, 1
      counting_class = self

      if association.through_reflection
        method_chain = association.chain.map do |association|
          if (source = association.source_reflection)
            raise "Chained associations without `inverse_of` are not supported!" unless source.inverse_of
            source.inverse_of.name
          else
            association.foreign_key
          end
        end

        proc do
          counter_id = method_chain.inject(self) do |memo, method|
            memo.send(method) unless memo.nil?
          end
          counter_id = counter_id.id if counter_id.is_a?(ActiveRecord::Base)

          counting_class.association_count_key counter_id, attribute_name, version
        end
      else
        foreign_key = association.foreign_key

        proc do
          counting_class.association_count_key send(foreign_key), attribute_name, version
        end
      end
    end

    def generate_association_relation_getter(association, options)
      counted_class = association.klass
      association_name = association.name
      if (scope_proc = options[:scope])
        -> { send(association_name).spawn.scoping { counted_class.instance_exec(&scope_proc) } }
      else
        -> { send(association_name).spawn }
      end
    end

  end
end

require 'cached_counts/railtie' if defined?(Rails)
