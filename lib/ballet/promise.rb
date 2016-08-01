module Ballet
  ##
  # A promise in Ballet is a pattern to easily wrap an async action, but
  # it works differently than promises in other frameworks.
  # As opposed to having methods to register callbacks to wait for values,
  # a `Promise` in KitchenSink lets you simply wait for a value to be delivered.
  #
  # The `await` method will pass control to the other fibers in KitchenSink
  # until the promise is filled or rejected.
  # When the promise is filled, control is passed back to your fiber, and 
  # your program resumes.
  # When the promise is rejected, the same thing happens, but an exception is
  # thrown instead.
  class Promise

    class Multi
      def initialize(promises)
        @promises = promises
      end

      def await
        @promises.map(&:await)
      end
    end

    ##
    # Create a new promise that allows you to await on many promises at once.
    #
    # promises
    # :   The array of promises to wait for
    def self.all(promises)
      Multi.new(promises)
    end

    def initialize
    end

    ##
    # Await the fullfilment of this promise, passing control to other fibers
    # until the value you want is available.
    def await
      EventManager.listen(self, Fiber.current) unless @value
      status, val = get_value
      if status == :bad
        raise val
      else
        val
      end
    end

    ##
    # Resolve this promise.
    # Control may not be passed to the fiber awaiting its value immediately,
    # but will be passed as soon as the resolution event is reached in the
    # event loop.
    def resolve!(val)
      if EventManager.has_listener? self
        EventManager.broadcast(self, [:ok, val])
      else
        @value = [:ok, val]
      end
    end

    ##
    # Reject this promise, throwing an exception to whomever is awaiting its
    # value. The exception will not be thrown immediately, but as soon as
    # the rejection event is released in the event loop.
    def reject!(except)
      if EventManager.has_listener? self
        EventManager.broadcast(self, [:bad, except])
      else
        @value = [:bad, except]
      end
    end

    protected

    def get_value
      @value || EventManager.transfer_fiber.transfer
    end
  end
end
