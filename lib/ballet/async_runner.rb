module Ballet

  class AsyncRunner
    def initialize(context, &block)
      @context = context
      @block = block
      @finished = false
    end

    attr_reader :fiber

    def make_fiber
      @fiber = Fiber.new do
        Thread.current[:fiber_context] = @context
        instance_eval(&@block)
        # Mark ourselves as being done with our synchronous work
        @finished = true
        # Transfer control to our nearest unfinished parent, which may be
        # the root context
        transfer_fiber.transfer
      end
      @fiber
    end

    def async(&block)
      AsyncRunner.new(self, &block).make_fiber.transfer
    end

    def transfer_fiber
      if @finished
        @context.transfer_fiber
      else
        @fiber
      end
    end

    protected

    def transfer_to_unfinished!
      ctx = @context
      while ctx.is_a?(self.class) && ctx.finished?
        ctx = ctx.context
      end
      ctx.fiber.transfer
    end

    def context
      @context
    end

    def finished?
      @finished
    end
  end
end
