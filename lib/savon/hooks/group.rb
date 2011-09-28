require "savon/hooks/hook"

module Savon
  module Hooks

    # = Savon::Hooks::Group
    #
    # Manages a list of hooks.
    class Group

      # Accepts an Array of +hooks+ to start with.
      def initialize(hooks = nil)
        self.hooks = hooks
      end

      attr_writer :hooks

      def hooks
        @hooks ||= []
      end

      # Adds a new hook.
      def define(id, hook, &block)
        hooks << Hook.new(id, hook, &block)
      end

      # Removes hooks matching the given +ids+.
      def reject!(*ids)
        ids = ids.flatten
        hooks.reject! { |hook| ids.include? hook.id }
      end

      # Returns a new group for a given +hook+.
      def select(hook)
        Group.new hooks.select { |h| h.hook == hook }
      end

      # Calls the hooks with the given +args+ and returns the
      # value of the last hooks.
      def call(*args)
        hooks.inject(nil) { |memo, hook| hook.call(*args) }
      end

    end
  end
end
