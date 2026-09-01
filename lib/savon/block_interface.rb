# frozen_string_literal: true

module Savon
  # Evaluates an options block against an {Options} target.
  #
  # A block expecting an argument receives the target directly. A block
  # without arguments is instance-evaluated, so bare setter calls reach the
  # target through {#method_missing} and unknown methods fall back to the
  # scope the block was defined in.
  class BlockInterface
    def initialize(target)
      @target = target
    end

    def evaluate(block)
      if block.arity.positive?
        block.call(@target)
      else
        @original = eval("self", block.binding, __FILE__, __LINE__)
        instance_eval(&block)
      end
    end

    private

    def method_missing(method, *args, &block)
      @target.send(method, *args, &block)
    rescue NoMethodError
      @original.send(method, *args, &block)
    end
  end
end
