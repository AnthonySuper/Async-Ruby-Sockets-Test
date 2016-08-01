require 'thread'
require 'fiber'
require_relative './async_runner.rb'

Thread.abort_on_exception = true

module Ballet
  ##
  # The EventManager handles the event loop, which is the core of Ballet.
  # It handles the various asynchronous events and their listeners.
  class EventManager
    ##
    # Start an event loop with a given block.
    # The block will be executed in the context of this event manager,
    # allowing you to use blocks passed to the `async` method to execute
    # asynchronously.
    #
    #     EventManager.run do
    #       async do
    #         reports = Report.get_all.await
    #         sum = reports.map(&:total_cost).sum
    #         SumManager.send_sum(sum).await
    #       end
    #       async do
    #         images = ImageHex.images.query(["wizard"]).await
    #         # nesting await blocks works as well
    #         images.each do |img|
    #           async do 
    #             file = img.download_file.await
    #             File.open(img.filename, "w") do |f|
    #               f.write(file)
    #             end
    #           end
    #         end
    #       end
    #     end
    # 
    def self.run(&block)
      @manager = self.new
      @manager.set_thread!(Thread.new do
        @manager.loop!(&block)
      end).join
    end

    ##
    # Broadcast an event to its listener.
    # event
    # :   The event to broadcast
    # data
    # :   The data to be passed to the event's listener.
    def self.broadcast(event, data)
      @manager.broadcast(event, data)
    end

    ##
    # Register a new listener, which will wait for an event.
    # Most of the time you do *not* want to call this method yourself,
    # unless you are writing library code. Even then, we recommend that
    # you make use of the Promise abstraction, which will be sufficient
    # in almost all cases.
    #
    # event
    # :   The event to wait for.
    #     This event should be broadcast later.
    #
    # listener
    # :   A fiber to transfer to, or an object that responds to `call`.
    #     In almost all cases you will wish to pass a fiber, as Ballet
    #     intentionally avoids callbacks whenver possible, but there may
    #     be some scenarios where the callback model is easier to reason about.
    def self.listen(event, listener)
      @manager.listen(event, listener)
    end

    ##
    # Determine if anybody is listening for an event.
    # event
    # :   The event to check.
    def self.has_listener?(event)
      @manager.has_listener?(event)
    end

    ##
    # Obtain the fiber to transfer to when waiting for some asynchronous
    # event to happen. Should generally never be called client-side.
    #
    # We recommend using the Promise abstraction instead of this API, as it
    # makes programming much simpler.
    def self.transfer_fiber
      (Thread.current[:fiber_context] || @manager).transfer_fiber
    end

    ##
    # Add a new poller.
    #
    # Pollers are objects which generate events.
    # They are called when the event queue is empty, in order to make new
    # events to process.
    # 
    # If we have no pollers, no events, and no listeners, we assume that
    # our work is done, and the event loop exits.
    def self.add_poller(poller)
      @manager.add_poller(poller)
    end

    ##
    # Remove a poller, signifying that it can no longer generate useful events.
    def self.remove_poller(poller)
      @manager.remove_poller(poller)
    end


    ##
    # :nodoc:
    def initialize
      @listeners = {}
      @pollers = []
      @spawners = []
      @queue = Queue.new
    end

    attr_reader :fiber

    def broadcast(id, data)
      @queue << [id, data]
    end

    def loop!(&block)
      # This gets complicated, so we try to explain this as much as we can.

      @mainfiber = Fiber.new do
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


    def loopfiber
      @loopfiber ||= Fiber.new do
        loop do
          poll_all_pollers
          while @listeners.empty?
            handle_empty_listeners
          end
          handle_event(@queue.pop) until @queue.empty?
        end
      end
    end
  end
end
