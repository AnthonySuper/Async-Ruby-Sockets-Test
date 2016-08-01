require 'thread'
require 'fiber'
require_relative './async_runner.rb'

Thread.abort_on_exception = true

module Ballet
  ##
  # The EventManager class handles the event loop.
  # This may be slightly obvious. Oh well.
  class EventManager
    ##
    # Start an event loop with a given block.
    # The block will be executed in the context of this event manager,
    # allowing you to use blocks passed to the `async` method to execute
    # asynchronously.
    def self.run(&block)
      @manager = self.new
      @manager.set_thread!(Thread.new do
        @manager.loop!(&block)
      end).join
    end

    ##
    # Get the current EventManager
    def self.current
      @manager
    end

    ##
    # Broadcast an event to whatever is listening for it.
    def self.broadcast(id, data)
      @manager.broadcast(id, data)
    end

    ## 
    # Begin executing a new block asyncronously.
    def self.async(&block)
      @manager.async(&block)
    end

    ##
    # See if a given event has a listener.
    def self.has_listener?(id)
      @manager.has_listener? id
    end

    ##
    # Get the fiber to transfer back to when you're waiting for an event.
    # This may be the root, event loop fiber, or another async fiber.
    def self.transfer_fiber
      (Thread.current[:fiber_context] || @manager).transfer_fiber
    end

    ##
    # Add a new poller.
    def self.add_poller(poller)
      @manager.add_poller(poller)
    end

    def self.remove_poller(poller)
      @manager.remove_poller(poller)
    end

    def initialize
      @listeners = {}
      @pollers = []
      @spawners = []
      @queue = Queue.new
    end

    attr_reader :fiber


    def loop!(&block)
      # This gets complicated, so we try to explain this as much as we can.

      # First, define an overall fiber that holds our sub-fibers
      @mainfiber = Fiber.new do
        # the loopfiber runs the event loop
        # We can't transfer control to this fiber until the setup
        # block is finished running.
        loopfiber = Fiber.new do
          loop do
            poll_all_pollers
            while @listeners.empty?
              handle_empty_listeners
            end
            handle_event(@queue.pop)
          end
        end


        # The blockfiber runs to setup our events and listeners.
        # Once that's finished, we transfer control to our loop fiber.
        # From then on, we always want to transfer control to the loop fiber.
        # This is why we set @fiber = loopfiber
        blockfiber = Fiber.new do
          instance_eval(&block)
          @fiber = loopfiber
          loopfiber.resume
        end

        # Allow all of our events to run properly
        while blockfiber.alive? do
          blockfiber.transfer
        end
      end

      # initially we want to run our setup block, so we set our 
      # @fiber to the overall main fiber
      @fiber = @mainfiber
      # We then run it 
      @fiber.resume 
    end

    def listen(id, listener)
      @listeners[id] = listener
    end

    def handle_event(event)
      id, data = event
      handler = @listeners.delete(id)
      if handler.is_a? Proc
        handler.call(data)
      else
        handler.transfer(data)
      end
    end

    def broadcast(id, data)
      @queue << [id, data]
    end

    def set_thread!(thread)
      @thread = thread
    end

    def async(&block)
      async_fiber = AsyncRunner.new(self, &block).make_fiber
      async_fiber.resume
    end

    def has_listener?(id)
      @listeners.has_key? id
    end

    def add_poller(poller)
      @pollers << poller
    end

    def remove_poller(poller)
      @pollers.delete(poller)
    end

    def transfer_fiber
      @fiber
    end

    def poll_all_pollers
      @pollers.each{|p| p.call}
    end

    def handle_empty_listeners
      if @pollers.empty?
        @mainfiber.transfer
      end
      poll_all_pollers
    end
  end
end
