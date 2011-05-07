module Savon

  # = Savon::Delegator
  #
  # Implements instance_eval with delegation.
  module Delegator

    # Processes a given +block+ by either evaluating it in the context of +self+ or
    # calling it with +self+ if the block expects an argument.
    def process(&block)
      raise ArgumentError, "Expected a block with an arity of either 0 or 1" if block.arity > 1
      block.arity == 1 ? block.call(self) : evaluate(&block)
    end

  private

    # Evaluates a given +block+ inside +self+ and stores the original block binding.
    def evaluate(&block)
      self.original_self = eval "self", block.binding
      instance_eval &block
    end

    attr_accessor :original_self

    # Handles calls to undefined methods by delegating to +original_self+.
    def method_missing(method, *args, &block)
      super unless original_self
      original_self.send method, *args, &block
    end

  end
end
