require "savon/hooks/hook"

module Savon
  module Hooks

    # = Savon::Hooks::Group
    #
    # Manages a list of hooks.
    class Group

      # Accepts an Array of +hooks+ to start with.
      def initialize(hooks = [])
        @hooks = hooks
      end

      # Returns whether this group contains hooks.
      def empty?
        hooks.empty?
      end

      # Returns the number of hooks in this group.
      def count
        hooks.count
      end

      # Adds a new hook.
      def define(id, hook, &block)
        hooks << Hook.new(id, hook, &block)
      end

      # Removes hooks matching the given +ids+.
      def reject(*ids)
        ids = ids.flatten
        hooks.reject! { |hook| ids.include? hook.id }
      end

      # Fire a given +hook+ with any given +args+.
      def fire(hook, *args, &callback)
        callable = select(hook)

        if callable.empty?
          callback.call
        else
          args.unshift(callback) if callback
          callable.call(*args)
        end
      end

      # Calls the hooks with the given +args+ and returns the
      # value of the last hooks.
      def call(*args)
        hooks.inject(nil) { |memo, hook| hook.call(*args) }
      end

      private

      def hooks
        @hooks ||= []
      end

      # Returns a new group for a given +hook+.
      def select(hook)
        Group.new hooks.select { |h| h.hook == hook }
      end

    end
  end
end
